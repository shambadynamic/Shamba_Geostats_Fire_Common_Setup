//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract GeoConsumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  int256 public geospatial_data;
  string public cid;
  uint256 public total_oracle_calls = 0;

  constructor(
  ) {
    setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
    setChainlinkOracle(0xf4434feDd55D3d6573627F39fA39867b23f4Bf7F);
  }

  mapping(uint256 => string) cids;

  function getCid(uint256 index)
        public
        view
        returns (string memory)
  {
        return cids[index];
  }

  function requestGeospatialData(
  )
    public
  {
    bytes32 specId = "83191779e6c74593b7a99bea8c116e31";
    uint256 payment = 1000000000000000000;
    Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillGeospatialData.selector);
    
    req.add("data", "{\"agg_x\": \"agg_min\", \"dataset_code\":\"COPERNICUS/S2_SR\", \"selected_band\":\"NDVI\", \"image_scale\":250.0, \"start_date\":\"2021-09-01\", \"end_date\":\"2021-09-10\", \"geometry\":{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":{\"id\":1},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[19.51171875,4.214943141390651],[18.28125,-4.740675384778361],[26.894531249999996,-4.565473550710278],[27.24609375,1.2303741774326145],[19.51171875,4.214943141390651]]]}}]}}");
        
    sendOperatorRequest(req, payment);
  }

  function fulfillGeospatialData(
    bytes32 requestId,
    int256 geospatialData,
    string calldata cidValue
  )
    public
    recordChainlinkFulfillment(requestId)
  {

    geospatial_data = geospatialData;
    
    cid = cidValue;
    cids[total_oracle_calls] = cid;
    total_oracle_calls = total_oracle_calls + 1;
  }

}