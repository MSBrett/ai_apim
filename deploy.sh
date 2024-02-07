#!/bin/sh
az account set --subscription "cab7feeb-759d-478c-ade6-9326de0651ff"
az deployment sub create --location eastus --template-file ./main.bicep --parameters ./alpha.parameters.bicepparam
