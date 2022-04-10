# Common External Adapter Setup for Shamba Geostats and Fire Data

1. The common external adapter is running on https://europe-west6-shamba-vpc-host-nonprod.cloudfunctions.net/shamba-common-external-adapter.

2. Create a bridge on the Chainlink Linkpool environment and use the above mentioned external adapter link as bridge url.

3. Set up the jobs on the Chainlink node as mentioned in the **JobSpecs** folder.

4. Use the Solidity Smart contracts' code given in the **SoliditySmartContracts** folder and replace the corresponding specId variables with the externalJobIDs for the respective jobs, and the contractAddress with the Operator contract address.

5. Deploy the smart contracts, fund them accordingly and then interact with the available functions and variables in order to get the desired data.