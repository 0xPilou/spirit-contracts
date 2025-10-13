#!/bin/bash

# Comprehensive script to extract and organize ABIs for all contracts in src/ directory
# Usage: ./extract-abis.sh
# Note: Run from the project root directory, will create abis/ in the project root

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to project root directory
cd "$SCRIPT_DIR"

# Create organized output directories
mkdir -p abis/{core,factory,interfaces,token,vesting}

echo "Extracting and organizing ABIs..."

# Core contracts
CORE_CONTRACTS=(
    "RewardController"
    "StakingPool"
)

# Factory contracts
FACTORY_CONTRACTS=(
    "EdenFactory"
)

# Token contracts
TOKEN_CONTRACTS=(
    "SpiritToken"
    "ChildSuperToken"
)

# Vesting contracts
VESTING_CONTRACTS=(
    "SpiritVesting"
    "SpiritVestingFactory"
)

# Interface contracts
INTERFACE_CONTRACTS=(
    "IRewardController"
    "IStakingPool"
    "IEdenFactory"
    "ISpiritToken"
    "IChildSuperToken"
    "ISpiritVestingFactory"
)

# Function to extract ABI
extract_abi() {
    local contract=$1
    local output_dir=$2
    local category=$3
    
    if [ -f "out/$contract.sol/$contract.json" ]; then
        echo "Extracting ABI for $contract -> abis/$category/"
        jq '.abi' "out/$contract.sol/$contract.json" > "abis/$category/$contract.json"
    else
        echo "Warning: $contract.json not found in out/$contract.sol/"
    fi
}

# Extract core contracts
echo "=== Core Contracts ==="
for contract in "${CORE_CONTRACTS[@]}"; do
    extract_abi "$contract" "core" "core"
done

# Extract factory contracts
echo "=== Factory Contracts ==="
for contract in "${FACTORY_CONTRACTS[@]}"; do
    extract_abi "$contract" "factory" "factory"
done

# Extract token contracts
echo "=== Token Contracts ==="
for contract in "${TOKEN_CONTRACTS[@]}"; do
    extract_abi "$contract" "token" "token"
done

# Extract vesting contracts
echo "=== Vesting Contracts ==="
for contract in "${VESTING_CONTRACTS[@]}"; do
    extract_abi "$contract" "vesting" "vesting"
done

# Extract interface contracts
echo "=== Interface Contracts ==="
for contract in "${INTERFACE_CONTRACTS[@]}"; do
    extract_abi "$contract" "interfaces" "interfaces"
done

echo ""
echo "ABI extraction complete! Organized structure:"
echo ""
echo "abis/"
echo "├── core/           # Core protocol contracts (RewardController, StakingPool)"
echo "├── factory/        # Factory contracts (EdenFactory)"
echo "├── interfaces/     # Contract interfaces"
echo "├── token/          # Token implementations (SpiritToken, ChildSuperToken)"
echo "└── vesting/        # Vesting contracts (SpiritVesting, SpiritVestingFactory)"
echo ""

# Show summary
echo "Summary:"
for category in core factory interfaces token vesting; do
    count=$(find "abis/$category" -name "*.json" 2>/dev/null | wc -l)
    echo "  $category/: $count ABIs"
done

echo ""
echo "Total ABIs extracted: $(find abis -name "*.json" | wc -l)"
echo "ABIs are located in: $(pwd)/abis/"
