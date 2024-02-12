# Sanday AI Spoke

## Introduction

This spoke is responsible to analyze consultation notes for potential billable procedures that can be reported to insurance providers. When eligible procedures are identified, they will be recommended to the GP for verification.

## Manual deployment

Deploy the spoke using the following command:

az deployment group what-if --resource-group rg-sanday-ai-acc --parameters ai.spoke-acc.biccepparam

az deployment group create --resource-group rg-sanday-ai-acc --parameters ai.spoke-acc.biccepparam