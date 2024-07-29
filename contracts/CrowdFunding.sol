// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    // List of existing projects
    Project[] private projects;

    // Event that will be emitted whenever a new project is started
    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );

    /** @dev Function to start a new project.
     * @param title Title of the project to be created
     * @param description Brief description about the project
     * @param durationInDays Project deadline in days
     * @param amountToRaise Project goal in wei
     */
    function startProject(
        string calldata title,
        string calldata description,
        uint256 durationInDays,
        uint256 amountToRaise
    ) external {
        uint256 raiseUntil = block.timestamp + durationInDays * 1 days;
        Project newProject = new Project(
            payable(msg.sender),
            title,
            description,
            raiseUntil,
            amountToRaise
        );
        projects.push(newProject);
        emit ProjectStarted(
            address(newProject),
            msg.sender,
            title,
            description,
            raiseUntil,
            amountToRaise
        );
    }

    /** @dev Function to get all projects' contract addresses.
     * @return A list of all projects' contract addresses
     */
    function returnAllProjects() external view returns (Project[] memory) {
        return projects;
    }
}

contract Project {
    // Data structures
    enum State {
        Fundraising,
        Expired,
        Successful
    }

    // State variables
    address payable public creator;
    uint256 public amountGoal; // required to reach at least this much, else everyone gets refund
    uint256 public completeAt;
    uint256 public currentBalance;
    uint256 public raiseBy;
    string public title;
    string public description;
    State public state = State.Fundraising; // initialize on create
    mapping(address => uint256) public contributions;

    // Event that will be emitted whenever funding will be received
    event FundReceived(
        address contributor,
        uint256 amount,
        uint256 currentTotal
    );
    // Event that will be emitted whenever the project starter has received the funds
    event CreatorPaid(address recipient);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(msg.sender == creator, "Not the creator");
        _;
    }

    constructor(
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 fundRaisingDeadline,
        uint256 goalAmount
    ) {
        creator = projectStarter;
        title = projectTitle;
        description = projectDesc;
        amountGoal = goalAmount;
        raiseBy = fundRaisingDeadline;
        currentBalance = 0;
    }

    /** @dev Function to fund a certain project.
     */
    function contribute() external payable inState(State.Fundraising) {
        require(msg.sender != creator, "Creator cannot contribute");
        contributions[msg.sender] += msg.value;
        currentBalance += msg.value;
        emit FundReceived(msg.sender, msg.value, currentBalance);
        checkIfFundingCompleteOrExpired();
    }

    /** @dev Function to change the project state depending on conditions.
     */
    function checkIfFundingCompleteOrExpired() public {
        if (currentBalance >= amountGoal) {
            state = State.Successful;
            payOut();
        } else if (block.timestamp > raiseBy) {
            state = State.Expired;
        }
        completeAt = block.timestamp;
    }

    /** @dev Function to give the received funds to project starter.
     */
    function payOut() internal inState(State.Successful) returns (bool) {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;

        (bool success, ) = creator.call{value: totalRaised}("");
        if (success) {
            emit CreatorPaid(creator);
            return true;
        } else {
            currentBalance = totalRaised;
            state = State.Successful;
        }

        return false;
    }

    /** @dev Function to retrieve donated amount when a project expires.
     */
    function getRefund() public inState(State.Expired) returns (bool) {
        require(contributions[msg.sender] > 0, "No contributions");

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amountToRefund}("");
        if (!success) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance -= amountToRefund;
        }

        return true;
    }
    function getInfo()
        public
        view
        returns (
            address payable projectStarter,
            string memory projectTitle,
            string memory projectDesc,
            uint256 deadline,
            State currentState,
            uint256 currentAmount,
            uint256 goalAmount
        )
    {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = amountGoal;
    }
}
