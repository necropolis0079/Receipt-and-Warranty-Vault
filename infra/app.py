#!/usr/bin/env python3
import os
import aws_cdk as cdk
from stacks.receipt_vault_stack import ReceiptVaultStack

app = cdk.App()

ReceiptVaultStack(
    app,
    "ReceiptVaultStack",
    env=cdk.Environment(
        account="882868333122",
        region="eu-west-1",
    ),
    description="Receipt & Warranty Vault - Serverless backend infrastructure",
)

app.synth()
