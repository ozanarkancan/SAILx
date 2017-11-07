using JLD

type Instruction
	fname #file name
	text #instruction as a list of tokens
	path #path as a list of (x,y,orientation) tuples
	map #map name
	id 
end
