// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PMKisanSubsidy {

    // Define the structure to store beneficiary information
    struct Beneficiary {
        string name;
        uint256 aadharNumber;  // Changed to uint256 for Aadhaar number
        uint256 bankAccount;   // Changed to uint256 for bank account number
        bool isEligible;
        bool isRegistered;
        uint256 balance;
    }

    // Store beneficiaries' details using their address (Ethereum address)
    mapping(address => Beneficiary) public beneficiaries;

    // Store the contract's balance
    uint256 public contractBalance;

    // Owner address to ensure only the owner can deposit funds
    address public owner;

    // Event for subsidy distribution
    event SubsidyDistributed(address indexed beneficiary, uint256 amount);
    event EtherDeposited(address indexed sender, uint256 amount);
    event BeneficiaryRegistered(address indexed beneficiary, string name, uint256 aadharNumber, uint256 bankAccount, bool isEligible);
    event EligibilityUpdated(address indexed beneficiary, bool isEligible);
    event BeneficiaryDetailsUpdated(address indexed beneficiary, uint256 aadharNumber, uint256 bankAccount);

    // Ensure only the contract owner can call restricted functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    // Ensure only the contract owner or a registered beneficiary can access certain functions
    modifier onlyRegistered() {
        require(beneficiaries[msg.sender].isRegistered, "You must be a registered beneficiary.");
        _;
    }

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender; // Set the owner as the account deploying the contract
    }

    // Function to deposit Ether into the contract by the owner
    function depositEther() public payable onlyOwner {
        require(msg.value > 0, "You must send some Ether to deposit.");
        contractBalance += msg.value;  // Increase the contract balance
        emit EtherDeposited(msg.sender, msg.value);
    }

    // Function to register beneficiaries with Aadhaar number, bank account, and eligibility
    function registerBeneficiary(address _beneficiary, string memory _name, uint256 _aadharNumber, uint256 _bankAccount, bool _isEligible) public onlyOwner {
        require(!beneficiaries[_beneficiary].isRegistered, "Beneficiary already registered.");
        
        beneficiaries[_beneficiary] = Beneficiary({
            name: _name,
            aadharNumber: _aadharNumber,
            bankAccount: _bankAccount,
            isEligible: _isEligible,
            isRegistered: true,
            balance: 0
        });

        emit BeneficiaryRegistered(_beneficiary, _name, _aadharNumber, _bankAccount, _isEligible);
    }

    // Function to update eligibility status of the beneficiary
    function updateEligibility(address _beneficiary, bool _isEligible) public onlyOwner {
        require(beneficiaries[_beneficiary].isRegistered, "Beneficiary not registered.");
        beneficiaries[_beneficiary].isEligible = _isEligible;
        emit EligibilityUpdated(_beneficiary, _isEligible);
    }

    // Function to update Aadhaar and bank account details of the beneficiary
    function updateBeneficiaryDetails(address _beneficiary, uint256 _aadharNumber, uint256 _bankAccount) public onlyOwner {
        require(beneficiaries[_beneficiary].isRegistered, "Beneficiary not registered.");
        beneficiaries[_beneficiary].aadharNumber = _aadharNumber;
        beneficiaries[_beneficiary].bankAccount = _bankAccount;
        emit BeneficiaryDetailsUpdated(_beneficiary, _aadharNumber, _bankAccount);
    }

    // Function to distribute subsidy to eligible beneficiaries
    function distributeSubsidy(address _beneficiary, uint256 _amount) public onlyOwner {
        // Ensure the contract has enough balance
        require(contractBalance >= _amount, "Insufficient contract balance.");

        // Ensure the beneficiary is registered and eligible
        require(beneficiaries[_beneficiary].isRegistered, "Beneficiary not registered.");
        require(beneficiaries[_beneficiary].isEligible, "Beneficiary not eligible.");

        // Transfer the subsidy
        beneficiaries[_beneficiary].balance += _amount;
        contractBalance -= _amount;

        // Emit an event for distribution
        emit SubsidyDistributed(_beneficiary, _amount);
    }

    // Function to check the contract balance
    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    // Function to get beneficiary details
    function getBeneficiary(address _beneficiary) public view returns (string memory, uint256, uint256, bool, bool, uint256) {
        Beneficiary memory ben = beneficiaries[_beneficiary];
        return (ben.name, ben.aadharNumber, ben.bankAccount, ben.isEligible, ben.isRegistered, ben.balance);
    }

    // Function for beneficiaries to claim their subsidy
    function claimSubsidy() public onlyRegistered {
        uint256 amount = beneficiaries[msg.sender].balance;
        require(amount > 0, "No subsidy available to claim.");

        // Reset balance after claiming
        beneficiaries[msg.sender].balance = 0;

        // Transfer subsidy to the beneficiary
        payable(msg.sender).transfer(amount);

        // Emit event for claiming subsidy
        emit SubsidyDistributed(msg.sender, amount);
    }
}

