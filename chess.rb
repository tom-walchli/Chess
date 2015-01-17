#############################################################
# 															#  
#  Assert validity of a sequence of moves on a chess board  #
# 															#
#############################################################

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
			puts "ID = #{@moveIDX}"
			assessValidMove(@movements[@moveIDX])
			@moveIDX += 1
		end
	end

	def self.posConverter(pos)
		return  [(pos[0]).ord-97,pos[1].to_i-1]
	end

	def self.posReConverter(pos)
		return (pos[0]+97).chr.to_s + (pos[1] + 1).to_s
	end

	def assessValidMove(movesAlpha)
		@movesAlpha = movesAlpha
		@pos1 		= ChessBoard.posConverter(movesAlpha[0])
		@pos2 		= ChessBoard.posConverter(movesAlpha[1])
		@dPos 		= [ @pos2[0] - @pos1[0] , @pos2[1] - @pos1[1] ] 

		piece1 		= @pieces[movesAlpha[0]]
		piece2 		= @pieces[@movesAlpha[1]]

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

		# dPos_new reduces dPos to unit steps and fractions thereof [-1..1, -1..1]
		# Obviously, if fractions occur, a move will not be possile... 	
		dPos_new = correctDPos(piece1,@dPos)
#		p "dPos_new: #{@dPos_new}"

		validMove = nil

		piece1.moves.each_with_index do |move,j|
			if move[0] == dPos_new[0] && move[1] == dPos_new[1]
				p "valid move found for #{piece1.class}: #{move}"
				validMove = move
				break
			end
		end

		if !validMove
			puts "no valid move found for #{piece1.class}     -- return"
			return
		end


		if !checkInitial(piece1,validMove)
			return
		end

		if !checkTake(piece1,mode,validMove)
			return
		end

		if obstructed(@pos1,@dPos, validMove, piece1)
			puts "you have an obstruction in the way...        -- return"
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

	def checkInitial(piece,validMove)
		if piece.class.to_s == "Pawn"
			if validMove[2] == "initial" && !piece.initial
				puts "This can only be done on the first move -- return"
				return false
			end
		end
		return true
	end

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
		@pieces['h1'] = Rook.new('white')	
		@pieces['a8'] = Rook.new('black')	
		@pieces['h8'] = Rook.new('black')	

		@pieces['b1'] = Knight.new('white')	
		@pieces['g1'] = Knight.new('white')	
		@pieces['b8'] = Knight.new('black')	
		@pieces['g8'] = Knight.new('black')	

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
		@moves  = [[2,1],[2,-1],[1,2],[1,-2],[-1,-2],[-1,2],[-2,1],[-2,-1]]
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

movements = [["b1", "a3"],["b2", "b4"],["a3", "c4"],["c4", "d6"],
			["c7", "d6"],["h2", "h4"],["h4", "h5"],["h1", "h4"],
			["h4", "a4"],["b8", "d7"],["e2", "e3"],["e3", "e2"]]
# movements = [["a2", "a3"],["a2", "a4"],["a2", "a5"],["a7", "a6"],
# 			["a7", "a5"],["a7", "a4"],["a7", "b6"],["b8", "a6"],
# 			["b8", "c6"],["b8", "d7"],["e2", "e3"],["e3", "e2"]]

ChessBoard.new(movements)
