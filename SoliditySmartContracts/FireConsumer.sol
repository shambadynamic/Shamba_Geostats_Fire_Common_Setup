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
    req.add("data", "{\"dataset_code\":\"MODIS/006/MOD14A1\", \"selected_band\":\"MaxFRP\", \"image_scale\":1000, \"start_date\":\"2021-09-01\", \"end_date\":\"2021-09-10\", \"geometry\":{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":{\"id\":1},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[29.53125,19.642587534013032],[29.53125,27.059125784374068],[39.90234375,27.059125784374068],[39.90234375,19.642587534013032],[29.53125,19.642587534013032]]]}},{\"type\":\"Feature\",\"properties\":{\"id\":2},\"geometry\":{\"type\":\"Polygon\",\"coordinates\":[[[46.72947724367683,4.390228926463396],[46.679357886244986,3.8826857905457652],[46.530925872748305,3.394358826483646],[46.28988536222383,2.9440946050840657],[45.965499406313945,2.5492840567467825],[45.57023397538652,2.2251800570298523],[45.11927889828469,1.9843023404026605],[44.62996412572296,1.8359528461951848],[44.12109374999999,1.7858585217968768],[43.61222337427702,1.8359528461951848],[43.122908601715295,1.9843023404026605],[42.67195352461347,2.2251800570298523],[42.27668809368605,2.5492840567467825],[41.95230213777616,2.9440946050840657],[41.71126162725168,3.394358826483646],[41.562829613755,3.8826857905457652],[41.51271025632316,4.390228926463396],[41.562829613755,4.8974271245416965],[41.71126162725168,5.3847719120817565],[41.95230213777616,5.833566543422026],[42.27668809368605,6.22664411740961],[42.67195352461348,6.549015711120945],[43.12290860171531,6.788425209793004],[43.612223374277036,6.9357938995827375],[44.12109375,6.9855438544859965],[44.629964125722964,6.9357938995827375],[45.119278898284705,6.788425209792991],[45.57023397538653,6.549015711120945],[45.965499406313945,6.226644117409597],[46.28988536222384,5.833566543422026],[46.53092587274831,5.384771912081744],[46.679357886244986,4.897427124541672],[46.72947724367683,4.390228926463396]]]}}]}}");
       
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