.DEFAULT_GOAL := build-contracts

.PHONY: install
install:
	yarn global add truffle
	yarn

# Auto copies "abi" array from build/contracts/Platform.json to ../app/src/PlatformABI.json after this
.PHONY: build-contracts
build-contracts:
	truffle compile
	make contracts-bin
	make contracts-pkg
	
.PHONY: test-contracts
test-contracts:
	truffle test

.PHONY: contracts-bin
contracts-bin:
	solc --abi --bin -o ./contracts --overwrite ./contracts/Platform.sol
.PHONY: contracts-pkg
contracts-pkg:
	abigen --abi=./contracts/Platform.abi --bin=./contracts/Platform.bin --pkg=abi --out=abi/abi.go

.PHONY: deploy-contracts-local
deploy-contracts-local:
	truffle migrate
	make post-deploy
.PHONY: deploy-contracts-sepolia
deploy-contracts-sepolia:
	truffle migrate --network sepolia
	make post-deploy
.PHONY: deploy-contracts-mainnet
deploy-contracts-mainnet:
	truffle migrate --network live
	make post-deploy
.PHONY: post-deploy
post-deploy:
	cp ./build/Platform.json ../app/src/PlatformABI.json
	jq '.abi' ../app/src/PlatformABI.json > temp.json && mv temp.json ../app/src/PlatformABI.
	

# load env variables into host machine terminal
.PHONY: env
env:
	@while IFS= read -r line || [[ -n "$$line" ]]; do \
        if [[ -n "$$line" && ! "$$line" =~ ^\s*# ]]; then \
            var_name="$$line" ; \
            var_value=$$(grep "$$var_name=" .env.dev | cut -d '=' -f 2-) ; \
            var_value="$$(echo "$$var_value" | sed -e 's/^ *//' -e 's/ *$$//')" ; \
            if [[ "$$var_value" != "" ]]; then \
                export "$$var_name"="$$var_value" ; \
            fi ; \
        fi ; \
    done < .env.dev