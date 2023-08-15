// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Platform {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    uint constant FEE = 0.0005 ether;
    uint constant MIN_REWARD = 0.001 ether;
    uint constant MIN_BID = 0.001 ether;

    mapping(uint => Project) public projects;
    mapping(uint => Application[]) public applications;
    mapping(uint => mapping(address => bool)) public hasApplied;

    uint[] public projectIds;
    uint public totalProjectsCount = 0;
    uint public nextProjectId = 1;

    event ProjectPosted(uint id);
    event ProjectUpdated(uint id);
    event ParticipantApplied(uint id, address participant, uint availableDate);
    event ParticipantApproved(uint id, address participant);
    event RewardReleased(uint id);

    struct Project {
        uint id;
        address payable author;
        address payable participant;
        uint reward;
        string title;
        string description;
        string[] skillsRequired;
        uint deadline;
        address payable[] candidates;
        bool rewardReleased;
    }

    struct Application {
        uint projectId;
        address payable applicant;
        uint bid;
        uint availableDate;
    }

    //
    // Payable functions

    function postProject(
        string memory title,
        string memory description,
        string[] memory skillsRequired,
        uint deadline,
        uint reward
    ) public payable {
        require(msg.value >= FEE, "Fee is not correct");
        require(reward >= MIN_REWARD, "Reward is less than minimum limit");
        require(deadline > block.timestamp, "Deadline must be in the future");

        Project storage p = projects[nextProjectId];
        p.id = nextProjectId;
        p.rewardReleased = false;
        p.author = payable(msg.sender);
        p.title = title;
        p.description = description;
        p.skillsRequired = skillsRequired;
        p.deadline = deadline;
        p.reward = reward;

        projectIds.push(nextProjectId); // Add the new project id to the array
        totalProjectsCount++; // Increment the total number of projects

        emit ProjectPosted(p.id);

        nextProjectId++;
    }

    function updateProject(
        uint id,
        uint newReward,
        string memory title,
        string memory description,
        string[] memory skillsRequired,
        uint deadline
    ) public payable {
        require(msg.value >= FEE, "Fee is not correct");
        require(deadline > block.timestamp, "Deadline must be in the future");

        Project storage p = projects[id];
        require(p.author == msg.sender, "Only author can update the project");
        require(
            p.participant == address(0),
            "Project can't be updated after participant has been assigned"
        );

        // If participant has not been assigned, author can update reward.
        if (p.participant == address(0)) {
            p.reward = newReward;
        }
        p.title = title;
        p.description = description;
        p.skillsRequired = skillsRequired;
        p.deadline = deadline;

        emit ProjectUpdated(id);
    }

    function applyForProject(
        uint id,
        uint bid,
        uint availableDate
    ) public payable {
        require(msg.value == FEE, "Fee is not correct");
        require(bid >= MIN_BID, "Bid is less than minimum limit");

        Project storage p = projects[id];
        // A project author cannot apply to its own project
        require(
            p.author != msg.sender,
            "Author cannot apply to their own project"
        );
        require(
            p.participant == address(0),
            "Project already has a participant"
        );
        require(
            availableDate > block.timestamp,
            "Available date must be in the future"
        );

        // Check if the user has already applied to the project
        require(
            !hasApplied[id][msg.sender],
            "User has already applied to this project"
        );

        // Mark that the user has applied for this project
        hasApplied[id][msg.sender] = true;

        p.candidates.push(payable(msg.sender)); // Add candidate to the project

        // Add application
        Application memory newApplication = Application({
            projectId: id,
            applicant: payable(msg.sender),
            bid: bid,
            availableDate: availableDate
        });

        applications[id].push(newApplication);

        emit ParticipantApplied(id, msg.sender, availableDate);
    }

    function approveApplicant(
        uint id,
        address payable candidate
    ) public payable {
        Project storage p = projects[id];

        uint candidateBid = 0;
        for (uint i = 0; i < applications[id].length; i++) {
            if (applications[id][i].applicant == candidate) {
                candidateBid = applications[id][i].bid;
                break;
            }
        }

        require(candidateBid > 0, "Candidate has not applied");
        require(msg.value == candidateBid, "Reward is not correct");

        require(
            p.author == msg.sender,
            "Only author can approve the applicant"
        );
        require(
            p.participant == address(0),
            "A participant has already been approved"
        );

        bool candidateExists = false;
        for (uint i = 0; i < p.candidates.length; i++) {
            if (p.candidates[i] == candidate) {
                candidateExists = true;
                break;
            }
        }
        require(candidateExists, "This candidate does not exist");

        p.participant = candidate;
        p.reward = candidateBid;

        emit ParticipantApproved(id, candidate);
    }

    function releaseReward(uint id) public payable {
        Project storage p = projects[id];
        require(
            p.participant != address(0),
            "No participant assigned to the project"
        );
        require(p.author == msg.sender, "Only author can release the reward");
        require(!p.rewardReleased, "Reward has already been released");

        uint platformCut = p.reward / 10;
        uint participantReward = p.reward - platformCut;

        p.participant.transfer(participantReward);

        p.rewardReleased = true;

        emit RewardReleased(id);
    }

    //
    // Read functions

    function getProjects() public view returns (uint[] memory) {
        return projectIds;
    }

    function getTotalProjectsCount() public view returns (uint256) {
        return totalProjectsCount;
    }

    function getProjectById(
        uint id
    )
        public
        view
        returns (
            uint,
            address,
            address,
            uint,
            string[] memory,
            string memory,
            string memory,
            uint,
            address[] memory
        )
    {
        Project memory p = projects[id];
        return (
            p.id,
            address(p.author),
            address(p.participant),
            p.reward,
            p.skillsRequired,
            p.title,
            p.description,
            p.deadline,
            stringsToAddresses(p.candidates)
        );
    }

    function getApplicationsForProject(
        uint id
    )
        public
        view
        returns (uint[] memory, address[] memory, uint[] memory, uint[] memory)
    {
        Application[] memory apps = applications[id];

        uint[] memory ids = new uint[](apps.length); // Renamed variable
        address[] memory applicants = new address[](apps.length);
        uint[] memory bids = new uint[](apps.length);
        uint[] memory availableDates = new uint[](apps.length);

        for (uint i = 0; i < apps.length; i++) {
            ids[i] = apps[i].projectId; // Updated line
            applicants[i] = apps[i].applicant;
            bids[i] = apps[i].bid;
            availableDates[i] = apps[i].availableDate;
        }

        return (ids, applicants, bids, availableDates);
    }

    function getApplicationByProjectIdAndUserAddress(
        uint projectId,
        address walletAddress
    ) public view returns (uint, uint) {
        Application[] storage apps = applications[projectId];

        for (uint i = 0; i < apps.length; i++) {
            if (apps[i].applicant == walletAddress) {
                return (apps[i].bid, apps[i].availableDate);
            }
        }

        return (0, 0);
    }

    //
    // Helper functions

    function getTotalLockedRewards() internal view returns (uint) {
        uint totalLocked = 0;
        for (uint i = 0; i < projectIds.length; i++) {
            uint id = projectIds[i];
            Project storage p = projects[id];
            if (p.participant != address(0) && !p.rewardReleased) {
                totalLocked += p.reward;
            }
        }
        return totalLocked;
    }

    function stringsToAddresses(
        address payable[] memory input
    ) private pure returns (address[] memory) {
        address[] memory output = new address[](input.length);
        for (uint i = 0; i < input.length; i++) {
            output[i] = address(input[i]);
        }
        return output;
    }

    //
    // Owner functions

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");

        uint totalLocked = getTotalLockedRewards();
        uint availableBalance = address(this).balance - totalLocked;

        require(availableBalance > 0, "No available balance for withdrawal");

        owner.transfer(availableBalance);
    }
}
