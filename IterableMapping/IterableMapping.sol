// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract IterableMapping is Ownable {
    struct Student {
        uint256 age;
        uint256 regNo;
        string name;
    }
    uint256 registrationID = 1;
    mapping(address => Student) private students;
    mapping(address => uint256) private addressIndex;
    address[] private addresses;
    
    function getRegistered(uint256 _age, string memory _name) external {
        require(students[msg.sender].age == 0, "Already Registered");
        students[msg.sender] = Student(_age, registrationID, _name);
        addressIndex[msg.sender] = addresses.length;
        addresses.push(msg.sender);
        registrationID++;
    }
    
    function getRegDetails(address _address)external view returns (uint256,uint256, string memory) {
        require(students[_address].age != 0, "Student does not exist.");
        return (students[_address].age, students[_address].regNo, students[_address].name);
    }
    
    function countRegisteredstudents()external view returns (uint256) {
        return addresses.length;
    }
    
    function getStudentDetails(uint256 _index)external view returns (address, uint256,uint256 ,string memory) {
        require(_index < addresses.length, "Index out of bounds.");
        address _address = addresses[_index];
        return (_address, students[_address].age,students[_address].regNo, students[_address].name);
    }

    function getIndexOfStudent(address _student) public view returns(uint256) {
        return addressIndex[_student];
    }

    function cancelRegistration(address _student) external onlyOwner {
        uint256 index = getIndexOfStudent(_student);
        addresses[index] = addresses[addresses.length -1];
        addresses.pop();
        delete students[_student];

    }
}
