pragma solidity ^0.4.15;

contract Reversi {

    // Turn no including pass
    uint public turn;
    // 0 == player1 1 == player2
    uint public turnOf;
    // players[0] is player1's address, players[1] is player2's address
    address[2] public players;
    // The array contains all pieces on board. (0, 0) is bottom left
    // 0 == empty, 1 == player1's piece, 2 == player2's piece
    // Usually player1's piece color is dark, and player2's, white.
    uint[8][8] public board;

    function Reversi() {
        turn = 0;
        turnOf = 0;

        // Set initial pieces
        board[3][3] = 1;
        board[3][4] = 0;
        board[4][3] = 1;
        board[4][4] = 0;
    }

    // Modifier that checks whether msg.sender is the player in turn
    modifier playerInTurn {
        require(players[0] != 0x0 && players[1] != 0x0);    // 2 players must be joined
        require(msg.sender == players[turnOf]);
        _;
    }

    /*
        Join a game as a player1 if there were no player joined, as player2 if a player1 has already joined.
    */
    function joinGame() {
        if (players[0] == 0x0) {
            players[0] = msg.sender;
        } else if (players[1] == 0x0) {
            players[1] = msg.sender;
        } else {
            // There are no seats left for you
            revert();
        }
    }

    /*
      Place a piece of the player in turn.
    */
    function placePiece(uint x, uint y) playerInTurn {
        setPiece(x, y, turnOf);

        // Start flipping pieces
        uint i;

        // Flipping +X direction
        for (i = x + 1; i < 8; i++) {
            if (board[i][y] == turnOf + 1) {
                // Same colored piece, flipping over
                break;
            } else {
                // Opponent's piece, flip it
                setPiece(i, y, (turnOf + 1) % 2 + 1);
            }
        }

        // Flipping -X direction
        for (i = x - 1; i >= 0; i--) {
            if (board[i][y] == turnOf + 1) {break;}
            else {setPiece(i, y, (turnOf + 1) % 2 + 1);}
        }

        // Flipping +Y direction
        for (i = y + 1; i < 8; i++) {
            if (board[x][i] == turnOf + 1) {break;}
            else {setPiece(x, i, (turnOf + 1) % 2 + 1);}
        }

        // Flipping -Y direction
        for (i = y - 1; i >= 0; i--) {
            if (board[x][i] == turnOf + 1) {break;}
            else {setPiece(x, i, (turnOf + 1) % 2 + 1);}
        }

        uint j;
        // Flipping +X+Y direction
        for (i = x + 1; i < 8; i++) {
            for (j = y + 1; j < 8; j++) {
                if (board[i][j] == turnOf + 1) {break;}
                else {setPiece(i, j, (turnOf + 1) % 2 + 1);}
            }
        }

        // Flipping +X-Y direction
        for (i = x + 1; i < 8; i++) {
            for (j = y - 1; j < 8; j--) {
                if (board[i][j] == turnOf + 1) {break;}
                else {setPiece(i, j, (turnOf + 1) % 2 + 1);}
            }
        }

        // Flipping -X-Y direction
        for (i = x - 1; i < 8; i--) {
            for (j = y - 1; j < 8; j--) {
                if (board[i][j] == turnOf + 1) {break;}
                else {setPiece(i, j, (turnOf + 1) % 2 + 1);}
            }
        }

        // Flipping -X+Y direction
        for (i = x - 1; i < 8; i--) {
            for (j = y + 1; j < 8; j++) {
                if (board[i][j] == turnOf + 1) {break;}
                else {setPiece(i, j, (turnOf + 1) % 2 + 1);}
            }
        }

        // End flipping pieces
    }

    /*
        Flip pieces as flipper, the direction is (ax, ay) ex. (1, 0) is +X, (1, 1) is +X+Y, (-1, 1) is -X+Y
        returns int value which shows how many times pieces are flipped with the function call
     */
    private int flipLine(int sx, int sy, int ax, int ay, int flipper) {
        int flipCount = 0;

        if (ay == 0) {
            // Flip horizontally
            // Pre determining how far away it should flip in line
            for (int x = sx; (0 <= x && x < 8); x+=ax) {
                int piece = getPiece(x, sy);

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
            for (int i = 0; i < flipCount; i++) {
            // Flip it
                setPiece(board, sx + ax * i, sy, flipper + 1);
            }
        } else if (ax == 0) {
            // Flip vertically, process is same with the above

            for (int y = sy; (0 <= y && y < 8); y+=ay) {
                int piece = getPiece(sx, y);

                if (piece == 0) {
                    return 0;
                } else if (piece == flipper + 1) {
                    break;
                } else {
                    flipCount++;
                }
            }

            for (int i = 0; i < flipCount; i++) {
                setPiece(board, sx, sy + ay * i, flipper + 1);
            }
        } else {
            // Flip diagonally

            int x = sx, y = sy;

            while ((0 <= x && x < 8) && (0 <= y && y < 8)) {
                int piece = getPiece(board, x, y);
                if (piece == 0) {
                    return 0;
                } else if (piece == flipper + 1) {
                    break;
                } else {
                    flipCount++;
                }

                x += ax;
                y += ay;
            }

            for (int i = 0; i < flipCount; i++) {
                setPiece(board, sx + ax * i, sy + ay * i, flipper + 1);
            }
        }
        return flipCount;
    }

    function setPiece(uint x, uint y, uint c) internal {
        require(x < 8 && y < 8);    // Checks if x and y are in bound (board size is 8 * 8)
        board[x][y] = c;
    }

    function passTurn() public playerInTurn {
        // Checks for a place to place a piece, if there are, you cannot pass.

        turn++;
        turnOf = (turnOf + 1) % 2;
    }

    function giveUpGame() public playerInTurn {
        // TODO to the owner
        selfdestruct(players[0]);
    }
}