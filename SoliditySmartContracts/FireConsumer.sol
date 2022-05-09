//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract FireConsumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  mapping(uint256 => uint256) public fire_data;
  string public cid;
  uint256 public total_oracle_calls = 0;

  constructor(
  ) {
    setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
    setChainlinkOracle(0xA623107254c575105139C499d4869b69582340cB);
  }

  mapping(uint256 => string) cids;

  function getCid(uint256 index)
        public
        view
        returns (string memory)
  {
        return cids[index];
  }

  function requestFireData(
  )
    public
  {
    bytes32 specId = "86d169c2904e487f954807313a20effa";
    uint256 payment = 1000000000000000000;
    Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillFireData.selector);
    req.add("data", "{\"dataset_code\":\"MODIS/006/MOD14A1\", \"selected_band\":\"MaxFRP\", \"image_scale\":1000, \"start_date\":\"2021-09-01\", \"end_date\":\"2021-09-10\", \"geometry\":{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":{\"id\":1},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[29.53125,19.642587534013032],[29.53125,27.059125784374068],[39.90234375,27.059125784374068],[39.90234375,19.642587534013032],[29.53125,19.642587534013032]]]}},{\"type\":\"Feature\",\"properties\":{\"id\":2},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[46.40625,13.752724664396988],[46.40625,20.138470312451155],[56.25,20.138470312451155],[56.25,13.752724664396988],[46.40625,13.752724664396988]]]}}]}}");
       
    sendOperatorRequest(req, payment);
  }

  function fulfillFireData(
    bytes32 requestId,
    uint256[] memory fireData,
    string calldata cidValue
  )
    public
    recordChainlinkFulfillment(requestId)
  {

    for (uint256 i = 0; i < fireData.length; i++) {
        fire_data[i + 1] = fireData[i];
    }

    cid = cidValue;
    cids[total_oracle_calls] = cid;
    total_oracle_calls = total_oracle_calls + 1;
  }

}