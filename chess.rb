

class ChessBoard
	attr_accessor :pieces
	def initialize(movements)
		@movements = movements
		initPieces
		@goodMove = true
		startMoving
	end

	def startMoving
		@moveIDX = 0
		while @goodMove && @moveIDX < @movements.length
			assessValidMove(@movements[@moveIDX])
			@moveIDX += 1
		end
	end

	def self.posConverter(pos)
		result = [(pos[0]).ord-97,pos[1].to_i-1]
#		p result
		return result
	end
	def self.posReConverter(pos)
		result = (pos[0]+97).chr.to_s + (pos[1] + 1).to_s
#		p result
		return result
	end

	def assessValidMove(movesAlpha)
		@movesAlpha = movesAlpha
		@pos1 		= ChessBoard.posConverter(movesAlpha[0])
		@pos2 		= ChessBoard.posConverter(movesAlpha[1])
		@dPos 		= [ @pos2[0] - @pos1[0] , @pos2[1] - @pos1[1] ] 
		piece1 		= @pieces[movesAlpha[0]]

		puts "ID = #{@moveIDX}"

		mode = []
		if !piece1 
			puts "no piece at pos1, #{movesAlpha[0]}          -- return"
			return
		end
		piece2 	= @pieces[@movesAlpha[1]]
		if piece2 && piece2.team == piece1.team
			puts "pos2 #{movesAlpha[1]} occupied by same team -- return"
			return
		elsif piece2
			puts "pos2 #{movesAlpha[1]} occupied by opponent #{piece2.class}"
			mode.push(:take)
		end

		moves = piece1.moves

		@dPos_new = correctDPos(piece1,@dPos)

		gotValidMove = nil

		moves.each_with_index do |move,j|
			if move[0] == @dPos_new[0] && move[1] == @dPos_new[1]
				gotValidMove = j
				p "valid move found for #{piece1.class}: #{move}"
				break
			end
		end
		if gotValidMove == nil
			puts "no valid move found for #{piece1.class}     -- return"
			return
		end

		validMove = moves[gotValidMove]

		if !checkInitial(piece1,validMove)
			return
		end

		if !checkTake(piece1,mode)
			return
		end

		if obstructed(@pos1,@dPos, validMove, piece1)
			puts "you have an obstruction on the way..."
			return
		end

		if mode.include?(:take)
			puts "ATTACK!!!"
			doTake(piece2,@movesAlpha[1])
		end

		doMove(piece1,@movesAlpha[0],@movesAlpha[1])
	end

	def doTake(piece,location)
		puts "removing #{piece.class} from #{location}." 
		@pieces.reject!{ |k| k == location } 
	end

	def doMove(piece, from,to)
		puts "moving #{piece.class} from #{from} to #{to}." 
		piece.initial = false
		@pieces[to] = piece
		@pieces.reject!{ |k| k == from }
	end

	def checkTake(piece,mode)
		if piece.class != "Pawn"
			return true
		end
		if validMove.include?(:take) && !mode.include?(:take)
			puts "This move is a take! nothing to take at destination"
			return false
		elsif !validMove.include?(:take) && mode.include?(:take)
			puts "This move is not allowed for a take"
			return false
		end
		return true
	end

	def checkInitial(piece,validMove)
		if piece.class != "Pawn"
			return true
		end
		if validMove.include?(:initial) && piece.initial == false
			puts "This can only be made on first move"
			return false
		end
		return true
	end

	def obstructed(pos1, dPos, goodMove, piece)
		if piece.class == "Knight"
			return false
		else
			maxAbs = dPos.map {|x| x.abs}.max
			j = 1
			while j < maxAbs
				newPos = pos1 + goodMove.collect { |n| n * j }
				@pieces.keys.each do |key|
					if ChessBoard.posConverter(key) == newPos
						return true
					end
				end
				j += 1
			end
		end
	end

	def correctDPos(piece1,dPos)
		if !piece1.moveLine
			return dPos
		else
			maxAbs = dPos.map {|x| x.abs}.max
			puts "MaxAbs: #{maxAbs}"
			return dPos.map {|x| x / maxAbs}
		end
	end

	def initPieces
		@pieces = {}
		@pieces['a2'] = Pawn.new('white')	
		@pieces['b2'] = Pawn.new('white')	
		@pieces['c2'] = Pawn.new('white')	
		@pieces['d2'] = Pawn.new('white')	
		@pieces['e2'] = Pawn.new('white')	
		@pieces['f2'] = Pawn.new('white')	
		@pieces['g2'] = Pawn.new('white')	
		@pieces['h2'] = Pawn.new('white')	
		@pieces['a7'] = Pawn.new('black')	
		@pieces['b7'] = Pawn.new('black')	
		@pieces['c7'] = Pawn.new('black')	
		@pieces['d7'] = Pawn.new('black')	
		@pieces['e7'] = Pawn.new('black')	
		@pieces['f7'] = Pawn.new('black')	
		@pieces['g7'] = Pawn.new('black')	
		@pieces['h7'] = Pawn.new('black')	

		@pieces['a1'] = Rook.new('white')	
		@pieces['a8'] = Rook.new('white')	
		@pieces['h1'] = Rook.new('black')	
		@pieces['h8'] = Rook.new('black')	

		@pieces['b1'] = Knight.new('black')	
		@pieces['g1'] = Knight.new('black')	
		@pieces['b8'] = Knight.new('white')	
		@pieces['g8'] = Knight.new('white')	

		@pieces['c1'] = Bishop.new('white')	
		@pieces['f1'] = Bishop.new('white')	
		@pieces['c8'] = Bishop.new('black')	
		@pieces['f8'] = Bishop.new('black')	

		@pieces['e1'] = Queen.new('white')	
		@pieces['e8'] = Queen.new('black')	

		@pieces['d1'] = King.new('white')	
		@pieces['d8'] = King.new('black')	
	end

end

class Piece
	attr_reader 	:team 		# white/black
	attr_reader 	:moves
	attr_reader 	:moveLine
	attr_accessor 	:initial

	def initialize(team)
		@team			= team
		@moveLine 		= false
		@initial 		= true
	end
end

class Pawn < Piece
	def initialize(team)
		super 
		@upDown = (team == "white" ? 1 : -1)
		@moves  = [[0,@upDown],[0,2*@upDown,'initial'],[1,@upDown,'take'],[-1,@upDown,'take']]
	end
end

class Bishop  < Piece #laeufer
	def initialize(team)
		super 
		@moveLine  = true
		@moves  = [[1,1],[1,-1],[-1,1],[-1,-1]]
	end
end

class Knight < Piece #Springer
	def initialize(team)
		super 
		@moves  = [[2,1],[2,-1],[1,2],[1,-2],[-1,-2],[-1,-2],[-2,1],[-2,-1]]
	end
end

class Rook < Piece #Turm
	def initialize(team)
		super 
		@moveLine  = true
		@moves  = [[1,0],[-1,0],[0,1],[0,-1]]
	end
end

class Queen < Piece
	def initialize(team)
		super 
		@moveLine  = true
		@moves  = [[1,0],[-1,0],[0,1],[0,-1],[1,1],[1,-1],[-1,1],[-1,-1]]
	end
end

class King < Piece
	def initialize(team)
		super 
		@moves  = [[0,1],[0,-1],[1,1],[1,0],[1,-1],[-1,-1],[-1,1],[-1,0]]
	end
end

movements = [["a2", "a3"],["a2", "a4"],["a2", "a5"],["a7", "a6"],
			["a7", "a5"],["a7", "a4"],["a7", "b6"],["b8", "a6"],
			["b8", "c6"],["b8", "d7"],["e2", "e3"],["e3", "e2"]]

ChessBoard.new(movements)