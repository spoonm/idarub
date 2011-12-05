#!/usr/bin/env ruby

#
# Game of life yo
#
# circular board
# crappy and sloppy implementation, don't reuse for anything
#

class GameOfLif
	attr_accessor :board

	def self.new_random(height, width)
		new((0..height).map { (0..width).map { rand(2) } })
	end

	def initialize(_board = [[]])
		self.board = _board
	end

	def num_neighbors(y, x)
		h, w = height, width
		board[y - 1  ][x - 1  ] +
		board[y - 1  ][x      ] +
		board[y - 1  ][(x+1)%w] +
		board[y      ][x - 1  ] +
		board[y      ][(x+1)%w] +
		board[(y+1)%h][x-1    ] +
		board[(y+1)%h][x      ] +
		board[(y+1)%h][(x+1)%w]
	end

	def alive?(y, x)
		board[y][x] == 1
	end

	def height
		board.length
	end
	def width
		board[0].length
	end

	def output
		str = ''
		board.each do |col|
			col.each do |cell|
				str << (cell == 0 ? ' ' : '*')
			end
			str << "\n"
		end
		return str
	end

	def next_board
		(0..height-1).map do |y|
			(0..width-1).map do |x|
				n = num_neighbors(y, x)
				if alive?(y, x)
					(n == 2 || n == 3) ? 1 : 0
				else
					(n == 3) ? 1 : 0
				end
			end
		end
	end

	def step
		self.board = next_board
	end
end
