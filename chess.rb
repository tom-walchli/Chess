#############################################################
# 															#  
#  Assert validity of a sequence of moves on a chess board  #
#              and draw board in console					#
# 															#
#############################################################
require 'colorize'

# system 'cls' before every move
syst_cls = false

class ChessBoard
	attr_reader :pieces

	# convert alphanumeric position (e.g. 'a7', 'b3', etc..) to array (e.g. [0,6], [1,2], etc.)
	def self.posConverter(pos) 		
		return  [(pos[0]).ord-97,pos[1].to_i-1]
	end

	# restore alphanumeric position from [x,y]
	def self.posReConverter(pos)
		return (pos[0]+97).chr.to_s + (pos[1] + 1).to_s
	end

	def initialize(movements, delay=3)
		@delay 		= delay
		@movements 	= movements
		initPieces
		@goodMove 	= true
		startMoving
	end

	def startMoving
		@moveIDX = 0
		while @goodMove && @moveIDX < @movements.length
			if $syst_cls
				system "cls" 
			end
			puts "\nID = #{@moveIDX}"
			assessValidMove(@movements[@moveIDX])
			puts "\n"
			Display.new(self)
			puts "\n\n"
			@moveIDX += 1
			sleep(@delay)
		end
	end

	def assessValidMove(movesAlpha) # ('alpha' for alphanumeric)
		@pos1 		= ChessBoard.posConverter(movesAlpha[0])
		@pos2 		= ChessBoard.posConverter(movesAlpha[1])

		# disable walking off the board
		if !checkNotOffBoard(@pos1) || !checkNotOffBoard(@pos2)
			puts "You are walking off the board!            -- return".red
			return
		end

		# difference of the two positions
		@dPos 		= [ @pos2[0] - @pos1[0] , @pos2[1] - @pos1[1] ] 

		piece1 		= @pieces[movesAlpha[0]]
		piece2 		= @pieces[movesAlpha[1]]

		# 'mode' is for now only used for 'take'
		mode = []
		if !piece1 
			puts "no piece at pos1, #{movesAlpha[0]}          -- return"
			return
		end
		if piece2 && piece2.team == piece1.team
			puts "pos2 #{movesAlpha[1]} occupied by same team -- return"
			return
		elsif piece2
			puts "pos2 #{movesAlpha[1]} occupied by opponent #{piece2.class}"
			mode.push(:take)
		end

		# dPos_new reduces dPos to unit steps [-1..1, -1..1] and fractions thereof
		# to check with allowed moves of Bishop, Rook and Queen
		dPos_new = correctDPos(piece1,@dPos)

		# see if piece1 is allowed to move in direction dPos_new
		validMove = nil
		piece1.moves.each_with_index do |move,j|
			if move[0] == dPos_new[0] && move[1] == dPos_new[1]
				p "valid move found for #{piece1.class}: #{move}"
				validMove = move
				break
			end
		end

		if !validMove
			puts "no valid move found for #{piece1.class}     -- return".red
			return
		end

		# check for Pawn if the move is only an initial move and if the pawn has previously been moved
		if !checkInitial(piece1,validMove)
			return
		end

		# check for Pawn if the move is allowed for a take (if mode == [:take]) or 
		# if the move is only for a take (if mode != [:take])
		if !checkTake(piece1,mode,validMove)
			return
		end

		# check if multi-unit moves are obstructed (does not apply to Knights)
		if obstructed(@pos1,@dPos, validMove, piece1)
			puts "you have an obstruction in your way...        -- return".yellow
			return
		end

		# If it's a take, remove piece2
		if mode.include?(:take)
			puts "ATTACK!!!".red
			doTake(piece2,movesAlpha[1])
		end

		# do the actual move...
		doMove(piece1,movesAlpha[0],movesAlpha[1])
	end

	# remove piece from @pieces
	def doTake(piece,location)
		puts "removing #{piece.class} from #{location}.".red
		@pieces.reject!{ |k| k == location } 
	end

	# move piece (from,to) in @pieces and update its internal position
	def doMove(piece, from,to)
		puts "moving #{piece.class} from #{from} to #{to}.".green 
		piece.initial  = false
		piece.posAlpha = to
		piece.position = ChessBoard.posConverter(to)
		@pieces[to]    = piece
		@pieces.reject!{ |k| k == from }
	end

	# check for Pawn if the move is allowed for a take (if mode == [:take]) or 
	# if the move is only for a take (if mode != [:take])
	def checkTake(piece,mode,validMove)
		if piece.class.to_s == "Pawn"
			# p validMove[2] == "take" 
			# p !mode.include?(:take)
			if validMove[2] == "take" && !mode.include?(:take)
				puts "This move is a take! nothing to take at destination -- return"
				return false
			elsif !validMove[2] == "take" && mode.include?(:take)
				puts "This move is not allowed for a take -- return"
				return false
			end
		end
		return true
	end

	# check for Pawn if the move is only an initial move and if the pawn has previously been moved
	def checkInitial(piece,validMove)
		if piece.class.to_s == "Pawn"
			if validMove[2] == "initial" && !piece.initial
				puts "This can only be done on the first move -- return"
				return false
			end
		end
		return true
	end

	def checkNotOffBoard(pos)
		pos.each do |coord|
			if coord.to_i > 7 || coord.to_i < 0 
				return false
			end
			return true
		end
	end

	# check if multi-unit moves are obstructed (does not apply to Knights)
	def obstructed(pos1, dPos, goodMove, piece)
		if piece.class.to_s == "Knight"
			return false
		else
			maxAbs = dPos.map {|x| x.abs}.max
			j = 1
			while j < maxAbs
				newPos = [ goodMove[0] * j + pos1[0] , goodMove[1] * j + pos1[1] ]
#				newPos = goodMove.each_with_index { |val, k| pos1[k] + (val * j) }
				@pieces.keys.each do |key|
					if ChessBoard.posConverter(key) == newPos
						p "Obstruction at: #{newPos} (#{ChessBoard.posReConverter(newPos)})"
						return true
					end
				end
				j += 1
			end
		end
		return false
	end

	# reduce dPos to unit steps [-1..1, -1..1] and fractions thereof
	# to check with allowed moves of Bishop, Rook and Queen
	def correctDPos(piece1,dPos)
		if !piece1.multiUnit
			return dPos
		else
			maxAbs = dPos.map {|x| x.abs}.max
			puts "MaxAbs: #{maxAbs}"
			return dPos.map {|x| x / maxAbs}
		end
	end

	def initPieces
		@pieces = {}
		@pieces['a2'] = Pawn.new('white','a2')	
		@pieces['b2'] = Pawn.new('white','b2')	
		@pieces['c2'] = Pawn.new('white','c2')	
		@pieces['d2'] = Pawn.new('white','d2')	
		@pieces['e2'] = Pawn.new('white','e2')	
		@pieces['f2'] = Pawn.new('white','f2')	
		@pieces['g2'] = Pawn.new('white','g2')	
		@pieces['h2'] = Pawn.new('white','h2')	
		@pieces['a7'] = Pawn.new('black','a7')	
		@pieces['b7'] = Pawn.new('black','b7')	
		@pieces['c7'] = Pawn.new('black','c7')	
		@pieces['d7'] = Pawn.new('black','d7')	
		@pieces['e7'] = Pawn.new('black','e7')	
		@pieces['f7'] = Pawn.new('black','f7')	
		@pieces['g7'] = Pawn.new('black','g7')	
		@pieces['h7'] = Pawn.new('black','h7')	

		@pieces['a1'] = Rook.new('white','a1')	
		@pieces['h1'] = Rook.new('white','h1')	
		@pieces['a8'] = Rook.new('black','a8')	
		@pieces['h8'] = Rook.new('black','h8')	

		@pieces['b1'] = Knight.new('white','b1')	
		@pieces['g1'] = Knight.new('white','g1')	
		@pieces['b8'] = Knight.new('black','b8')	
		@pieces['g8'] = Knight.new('black','g8')	

		@pieces['c1'] = Bishop.new('white','c1')	
		@pieces['f1'] = Bishop.new('white','f1')	
		@pieces['c8'] = Bishop.new('black','c8')	
		@pieces['f8'] = Bishop.new('black','f8')	

		@pieces['e1'] = Queen.new('white','e1')	
		@pieces['e8'] = Queen.new('black','e8')	

		@pieces['d1'] = King.new('white','d1')	
		@pieces['d8'] = King.new('black','d8')	
	end

end

class Piece
	# moves     : A list of allowed moves
	# 		      for Bishop, Knight and Queen: single unit moves
	# multiUnit : Whether or not multi unit moves are allowed for the Piece
	# team		: white or black...
	# initial   : only relevant for Pawn. Whether or not he's been moved before
	# symbol	: how the piece appears in Display
	# posAlpha 	: Alphanumeric position of the piece ('a5', 'b3', etc..)
	# position  : position in zero-based coordinates ('a5' -> [0,4])
	attr_reader 	:team , :moves , :multiUnit , :symbol
	attr_accessor 	:initial , :posAlpha , :position

	def initialize(team, pos)
		@posAlpha		= pos
		@position		= ChessBoard.posConverter(pos)
		@team			= team
		@multiUnit 		= false
		@initial 		= true
	end
end

class Pawn < Piece
	def initialize(team, pos)
		super 
		@symbol = (team == "white" ? "P" : "p")
		@upDown = (team == "white" ? 1 : -1)
		@moves  = [[0,@upDown],[0,2*@upDown,'initial'],[1,@upDown,'take'],[-1,@upDown,'take']]
	end
end

class Bishop  < Piece #laeufer
	def initialize(team, pos)
		super 
		@symbol = (team == "white" ? "B" : "b")
		@multiUnit  = true
		@moves  = [[1,1],[1,-1],[-1,1],[-1,-1]]
	end
end

class Knight < Piece #Springer
	def initialize(team, pos)
		super 
		@symbol = (team == "white" ? "K" : "k")
		@moves  = [[2,1],[2,-1],[1,2],[1,-2],[-1,-2],[-1,2],[-2,1],[-2,-1]]
	end
end

class Rook < Piece #Turm
	def initialize(team, pos)
		super 
		@multiUnit  = true
		@symbol = (team == "white" ? "R" : "r")
		@moves  = [[1,0],[-1,0],[0,1],[0,-1]]
	end
end

class Queen < Piece
	def initialize(team, pos)
		super 
		@multiUnit  = true
		@symbol = (team == "white" ? "Q" : "q")
		@moves  = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
	end
end

class King < Piece
	def initialize(team, pos)
		super 
		@symbol = (team == "white" ? "W" : "w")
		@moves  = [[0,1],[0,-1],[1,1],[1,0],[1,-1],[-1,-1],[-1,1],[-1,0]]
	end
end

class Display
	def initialize (chessBoard)
		@chessBoard = chessBoard
		@fullBoard  = fillBoard
		drawBoard(@fullBoard)
	end

	# fill an array with 8x8 blanks and replace blanks with Pieces, where they stand:
	# ["rkbwqbkr",
	#  "pppppppp",
	#  "        ",
	#  "        ",
	#  "        ",
	#  "        ",
	#  "PPPPPPPP",
	#  "RKBWQBKR"]
	#  ... for the opening position
	def fillBoard
		blank = ((" "*8 + ",") * 8).split(",")
		@chessBoard.pieces.keys.each do |key|
			piece = @chessBoard.pieces[key]
			pos = piece.position
			s = blank[pos[1]]
			s[pos[0]] = piece.symbol
			blank[pos[1]] = s
		end
		return blank
	end

	# draw the board around char-array from fillBoard()
	def drawBoard(charArr)
		delim 		= " | "
		delimDbl 	= " || "
		@baseChars  = ("  " + delimDbl + ("a".."h").to_a.join(delim) + delimDbl + "  ")
		@hLine	 	= ("-" * 41)
		@hLineDbl 	= ("=" * 41)
		board 		= []
		board.push(@baseChars)
		board.push(@hLineDbl)
		for j in (0..7)
			board.push(" #{j+1}#{delimDbl}#{charArr[j].split("").join(delim)}#{delimDbl}#{j+1} ")
			board.push(@hLine)
		end
		board.pop
		board.push(@hLineDbl)
		board.push(@baseChars)
		puts board.reverse
	end
end

movements = [["b1", "a3"],["b2", "b4"],["a3", "c4"],["c4", "d6"],
			["c7", "d6"],["h2", "h4"],["h4", "h5"],["h1", "h4"],
			["h4", "a4"],["b8", "d7"],["e2", "e3"],["e3", "e2"]]
# movements = [['b2','b3'],['f2','b7'],['b4','a8'],['a8','g5'],['b2','b4'],['h7','f6'],['e3','b1'],['b7','e4'],
# ['b2','b5'],['g7','g2'],['f7','f8'],['g7','e8'],['f5','g5'],['f7','f6'],['c3','a2'],['e1','c1'],['f7','f5'],
# ['g8','c6'],['b2','d5'],['f7','f4'],['f6','f3'],['c5','f4'],['b6','a5'],['c3','d7'],['b2','f6'],['e4','d8'],
# ['d2','g6'],['b2','c3'],['a3','g5'],['h6','e8'],['d3','b5'],['d6','f3'],['c5','c4'],['f6','a3'],['b7','c1'],
# ['f1','f1'],['b6','b4'],['a7','e5'],['b6','c5'],['c2','e7'],['d4','f5'],['a7','g8'],['a7','d1'],['c5','b4'],
# ['c4','e3'],['h4','h3'],['b5','b2'],['b2','g4'],['h3','h4'],['h8','d3'],['h8','h7'],['h2','h3'],['e8','c4'],
# ['a3','a1'],['d3','b5'],['a3','a1'],['d5','d3'],['d5','f5'],['b4','f6'],['d5','g2'],['c8','d4'],['d5','b5'],
# ['c6','d5'],['f3','b5'],['a1','g6'],['g6','e5'],['d3','e6'],['g6','a7'],['g6','h4'],['c6','d8'],['a3','h8'],
# ['g8','f8'],['c7','f2'],['d3','c4'],['a5','a4'],['a5','b5'],['f1','a8'],['c2','g1'],['e5','a4'],['h5','f1'],
# ['e6','g4'],['g5','h2'],['c3','b2'],['h2','c7'],['e6','f3'],['c3','c4'],['f1','c4'],['b3','a6'],['c4','b3'],
# ['c1','h6'],['a5','c5'],['f4','f7'],['c2','c6'],['f6','g2'],['d2','a1'],['e4','a3'],['c2','d3'],['a8','c6'],
# ['d6','d1'],['c2','e4'],['d6','g2'],['a6','a7'],['c2','c4'],['a8','a7'],['c4','d3'],['c3','h5'],['b4','c7'],
# ['e6','d5'],['b6','d6'],['e5','f8'],['f1','f6'],['a8','a6'],['a8','c6'],['e4','e5'],['h2','a5'],['c8','e1'],
# ['e3','h2'],['f3','h3']]

# movements = [["a2", "a3"],["a2", "a4"],["a2", "a5"],["a7", "a6"],
# 			["a7", "a5"],["a7", "a4"],["a7", "b6"],["b8", "a6"],
# 			["b8", "c6"],["b8", "d7"],["e2", "e3"],["e3", "e2"]]

# ChessBoard (Array of moves, Delay between moves [sec] = 3)
ChessBoard.new(movements) 