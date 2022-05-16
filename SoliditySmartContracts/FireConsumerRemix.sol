//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FireConsumerRemix is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    mapping(uint256 => uint256) private fire_data;
    string private cid;
    uint256 public total_oracle_calls = 0;

    mapping(uint256 => string) private cids;


    struct Geometry {
        uint256 property_id;
        string coordinates;
    }

    mapping(uint256 => Geometry) geometry;


    function addGeometry(
        uint256 property_id,
        string memory coordinates
    ) public {
        Geometry memory g = Geometry({
            property_id: property_id,
            coordinates: coordinates
        });

        geometry[property_id] = g;
    }

    function getGeometry(uint256 property_id)
        public
        view
        returns (Geometry memory)
    {
        return geometry[property_id];
    }

    function getCid(uint256 index)
        public
        view
        returns (string memory)
    {
        return cids[index];
    }

    constructor() {
        setChainlinkToken(0xa36085F69e2889c224210F603D836748e7dC0088);
        setChainlinkOracle(0xe2edEB50A3248256A3c56f782f6BB4157B08549c);
    }

    function concat(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return (string(abi.encodePacked(a, "", b)));
    }

    function requestFireData(
        string memory dataset_code,
        string memory selected_band,
        string memory image_scale,
        string memory start_date,
        string memory end_date,
        uint256 geometry_length
    ) public {
        bytes32 specId = "7a79785a50584020b9a1b95cf624c848";

        uint256 payment = 1000000000000000000;
        Chainlink.Request memory req = buildChainlinkRequest(
            specId,
            address(this),
            this.fulfillFireData.selector
        );

        string memory concatenated_data = concat(
            '{"dataset_code":"',
            dataset_code
        );
        concatenated_data = concat(concatenated_data, '", "selected_band":"');
        concatenated_data = concat(concatenated_data, selected_band);
        concatenated_data = concat(concatenated_data, '", "image_scale":');
        concatenated_data = concat(concatenated_data, image_scale);
        concatenated_data = concat(concatenated_data, ', "start_date":"');
        concatenated_data = concat(concatenated_data, start_date);
        concatenated_data = concat(concatenated_data, '", "end_date":"');
        concatenated_data = concat(concatenated_data, end_date);
        concatenated_data = concat(
            concatenated_data,
            '", "geometry":{"type":"FeatureCollection","features":['
        );

        for (uint256 i = 0; i < geometry_length; i++) {
            concatenated_data = concat(
                concatenated_data,
                '{"type":"Feature","properties":{"id":'
            );
            concatenated_data = concat(
                concatenated_data,
                Strings.toString(geometry[i + 1].property_id)
            );
            concatenated_data = concat(
                concatenated_data,
                '},"geometry":{"type":"Polygon","coordinates":'
            );
            concatenated_data = concat(
                concatenated_data,
                geometry[i + 1].coordinates
            );
            concatenated_data = concat(concatenated_data, "}}");

            if (i != geometry_length - 1) {
                concatenated_data = concat(concatenated_data, ",");
            }
        }
        concatenated_data = concat(concatenated_data, "]}}");
        string memory req_data = concatenated_data;

        req.add("data", req_data);

        sendOperatorRequest(req, payment);
    }

    function fulfillFireData(bytes32 requestId, uint256[] memory fireData, string calldata cidValue)
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
    

    function getFireData(uint256 propertyID)
        public
        view
        returns (uint256)
    {
        return fire_data[propertyID];
    }
}