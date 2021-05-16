// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Ballot {

//Now we have to write the struct to represent a single vote holder. It holds the information whether the person voted, and (if they did) which option they chose.
//If they trusted someone else with their ballot, you can see the new voter in the address line. Delegation also makes weight accumulate:

  struct Voter {
        uint weight;
        bool if_voted;
        address delegated_to;
        uint voter;
    }


}
   
//This next struct will represent a single SubPoll. Its name can’t be bigger than 32 bytes. 
//The voteCount shows you how many votes the poll has received:

  struct SubPoll {
        bytes32 name;
        uint voteCount;
       
    }

    address public chairperson;

    //By using the mapping keyword, we declare a state variable necessary for assigning the blockchain voting rights. 
    //It stores the struct we created to represent the voter in each address required:

    mapping(address => Voter) public voters;

    //Next, we include a subPoll structs array. It will be dynamically-sized:

    SubPoll[] public subPolls;

    //Then, we create a new ballot to choose one of the subPolls. 
    //Each new subPoll name requires creating a new subPoll object and placing it at the end of our array:

    constructor(bytes32[] memory subPollNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < subPollNames.length; i++) {
            subPolls.push(SubPoll({ 
                name: subPollNames[i],
                voteCount: 0
            }));
        }
    }

    //Now it’s time to provide the voter with a right to use their ballot. Only the chairperson can call this function.
    //If the first argument of require returns false, function stops executing. All the changes it has made are cancelled too.
    //Using require helps you check if the function calls execute as they should. 
    //If they don’t, you may include an explanation in the second argument:

    function giveRightToVote(address voter, uint256 amountOfTokens, uint256 votesRemaining) public {
        require(
            msg.sender == chairperson,
            "Only the chairperson can assign voting rights."
        );

        require(
            !voters[voter].voted,
            "The voter has used their ballot."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = amountOfTokens;
    }

  //Next, we will write a function to delegate the vote. to represents an address to which the voting right goes. If they delegate as well, the delegation is forwarded.
  //We also add a message to inform about a located loop. Those can cause issues if they run for a long time. 
  //In such case, a contract might get stuck, as delegation may need more gas than a block has available.

   function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You have already voted.");

        require(to != msg.sender, "You cant delegate to yourself.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation!");
        }

  //sender is a reference that affects voters[msg.sender].voted. 
  //If the delegate has used their ballot, it adds to the total number of received votes. If they haven’t, their weight increases:
  
    sender.voted = true;
          sender.delegate = to;
          Voter storage delegate_ = voters[to];
          if (delegate_.voted) {
              subPolls[delegate_.vote].voteCount += sender.weight;
          } else {
              delegate_.weight += sender.weight;
          }
      }

  //vote allows giving your vote to a certain proposal, along with any votes you may have been delegated:

    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Cannot vote");
        require(!sender.voted, "Has voted.");
        sender.voted = true;
        sender.vote = proposal;
        subPolls[proposal].voteCount += sender.weight;
    }

    //Finally, by calling winningProposal() we count the votes received and choose the winner of our blockchain election. 
    //To get their index and return a name, we use winnerName():

  function winningSubPoll() public view
            returns (uint winningSubPoll_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < subPolls.length; p++) {
            if (subPolls[p].voteCount > winningVoteCount) {
                winningVoteCount = subPolls[p].voteCount;
                winningSubPoll_ = p;
            }
        }
    }

    function winnerName() public view
            returns (bytes32 winnerName_)
    {
        winnerName_ = subPolls[winningSubPoll()].name;
    }
}













