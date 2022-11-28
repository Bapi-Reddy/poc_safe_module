include .env

run_test:
	@forge test --fork-url ${ARBITRUM_RPC} --fork-block-number ${ARBITRUM_BLOCK} -vv
deploy_demo:
	@forge build
	@forge script script/Deploy.s.sol --sig "run()" --rpc-url ${MATIC_RPC} --private-key ${PRIV_KEY} -v --broadcast


verify_demo:
	@forge verify-contract --chain-id 137 0xd1e3d59749f7e3ae67162810dbf35f2840969dd6 "src/TaskDemo.sol:TaskDemo" ${POLYGONSCAN_KEY} --watch --constructor-args $$(cast abi-encode "constructor(address)" 0x527a819db1eb0e34426297b03bae11F2f8B3A19E)

