pragma solidity ^0.4.15;

contract Reversi {

    // Turn number including pass
    uint public turn;
    // 0 == player1 1 == player2
    uint public turnOf;
    // players[0] is player1's address, players[1] is player2's address
    address[2] public players;
    // This uint256 variable has all pieces on the board. (0, 0) is at 0 bit and value is 2 bit length
    // 0 == empty, 1 == player1's piece, 2 == player2's piece
    // Normally, storing position = 2 * ((8 * y) + x) [bit]
    // Usually player1's piece color is dark, and player2's white.
    uint256 public board;

    function Reversi() public {
        turn = 0;
        turnOf = 0;

        // Set initial pieces
        /*
         0000000000000000
         0000000000000000
         0000000000000000
         0000001001000000
         0000000110000000 ^
         0000000000000000 |y
         0000000000000000
         0000000000000000
                 <- x
        */
        board = 0x2400180000000000000;
    }

    // Modifier that checks whether msg.sender is the player in turn
    modifier playerInTurn {
        require(players[0] != 0x0 && players[1] != 0x0);    // 2 players must be joined
        require(msg.sender == players[turnOf]);
        _;
    }

    // function fancyBoard() public constant returns (string) {
    //     string memory rst= "";

    //     for (uint x = 0; x < 8; x++) {
    //         for (uint y = 0; y < 8; y++) {
    //             uint piece = getPiece(x, y);

    //             if (piece == 0) {
    //                 rst += " ";
    //             } else if (piece == 1) {
    //                 rst += "●";
    //             } else {
    //                 rst += "○";
    //             }
    //         }
    //         rst += "\n";
    //     }
    // }

    /*
        Join a game as a player1 if there were no player joined, as player2 if a player1 has already joined.
    */
    function joinGame() public {
        // Reject if the msg.sender is already the player of the game
        if (players[0] == msg.sender || players[1] == msg.sender) revert();

        if (players[0] == 0x0) {
            players[0] = msg.sender;
        } else if (players[1] == 0x0) {
            players[1] = msg.sender;
        } else {
            // There are no seats left for you
            revert();
        }
    }

    function passTurn() public playerInTurn {
        // TODO Checks for a place to place a piece, if there are, you cannot pass.

        turn++;
        turnOf = (turnOf + 1) % 2;
    }

    function giveUpGame() public playerInTurn {
        // TODO to the owner
        selfdestruct(players[0]);
    }

    /*
      Place a piece of the player in turn. This also do flipping thing.
    */
    function placePiece(uint x, uint y) public playerInTurn {
        require(getPiece(x, y) == 0);   // The place has to be empty
        // It first set a piece of the player to where he/she wanted to place
        setPiece(x, y, turnOf + 1);

        // Start flipping pieces
        uint totalFlipping = 0;

        // Flipping X direction
        totalFlipping += flipLine( x + 1 , y     ,  1,  0, turnOf );
        totalFlipping += flipLine( x - 1 , y     , -1,  0, turnOf );
        // Flipping Y direction
        totalFlipping += flipLine( x     , y + 1 ,  0,  1, turnOf );
        totalFlipping += flipLine( x     , y - 1 ,  0, -1, turnOf );
        // Flipping diagonal direction
        totalFlipping += flipLine( x + 1 , y + 1 ,  1,  1, turnOf );
        totalFlipping += flipLine( x + 1 , y - 1 ,  1, -1, turnOf );
        totalFlipping += flipLine( x - 1 , y - 1 , -1, -1, turnOf );
        totalFlipping += flipLine( x - 1 , y + 1 , -1,  1, turnOf );

        if (totalFlipping == 0) {
            // Nothing to flip means you cannot place a piece there,
            // if there is nowhere to place then use passTurn() instead.

            revert();   // Yes sure it wrote down some changes in the memory,
            // but since it have not overwrited the nuko blockchain,
            // revert() prevents from writing a broken board state
            // to the blockchain.
            // PS. I added some thing and a writing problem has gone
            // entirely.
        }

        // End flipping pieces

        // Let it proceed to next turn
        turn++;
        turnOf = (turnOf + 1) % 2; // If now player1 is placed a piece then next turns player would be player2, otherwise player1

    }

    /*
        Flip pieces as flipper, the direction is (ax, ay) ex. (1, 0) is +X, (1, 1) is +X+Y, (-1, 1) is -X+Y
        returns int value which shows how many times pieces are flipped with the function call
     */
    function flipLine(uint sx, uint sy, int ax, int ay, uint flipper) internal returns (uint) {
        uint x = 0;
        uint y = 0;
        uint i = 0;
        uint piece = 0;
        uint flipCount = 0;

        if (ay == 0) {
            // Flip horizontally
            // Pre determining how far away it should flip in line
            for (x = sx; (0 <= x && x < 8); x = uint(int(x) + ax)) {
                piece = getPiece(x, sy);

                if (piece == 0) {
                    // Nothing more is there, no flipping would happen
                    return 0;
                } else if (piece == flipper + 1) {
                    // Flipper colored piece, flipping ends
                    break;
                } else {
                    // Opponent's piece, will flip it
                    flipCount++;
                }
            }

            // Flipping pieces real this time
            for (i = 0; i < flipCount; i++) {
                // Flip it
                setPiece(uint(int(sx) + ax * int(i)), sy, flipper + 1);
            }
        } else if (ax == 0) {
            // Flip vertically, process is same with the above

            for (y = sy; (0 <= y && y < 8); y = uint(int(y) + ay)) {
                piece = getPiece(sx, uint(y));

                if (piece == 0) {
                    return 0;
                } else if (piece == flipper + 1) {
                    break;
                } else {
                    flipCount++;
                }
            }

            for (i = 0; i < flipCount; i++) {
                setPiece(sx, uint(int(sy) + ay * int(i)), flipper + 1);
            }
        } else {
            // Flip diagonally

            x = sx;
            y = sy;

            while ((0 <= x && x < 8) && (0 <= y && y < 8)) {
                piece = getPiece(x, y);

                if (piece == 0) {
                    return 0;
                } else if (piece == flipper + 1) {
                    break;
                } else {
                    flipCount++;
                }

                x = uint(int(x) + ax);
                y = uint(int(y) + ay);
            }

            for (i = 0; i < flipCount; i++) {
                setPiece(uint(int(sx) + ax * int(i)), uint(int(sy) + ay * int(i)), flipper + 1);
            }
        }

        return flipCount;
    }

    function getPiece(uint x, uint y) internal constant returns (uint) {
        require(x < 8 && y < 8);
        // Shift right to get the value at index being the first digit, and erase all bits upper 3 bit (do AND 0b11)
        return (board >> (2 * ((8 * y) + x))) & 3;
    }

    function setPiece(uint x, uint y, uint c) internal {
        require(x < 8 && y < 8);    // Checks if x and y are in bound (board size is 8 * 8)
        // FIXME may be we should check the bounds for c

        // Erase the value at index, and write the value c
        // Attention at the conversion to uint256, because number '3' is comprehended as uint8, without it,
        // the result of the shifting will be overflowed and might be messed up
        uint index = 2 * ((8 * y) + x);
        board = (board & (~(uint256(3) << index))) | (c << index);
    }
}