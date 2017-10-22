/*
 * +===============================================
 * | Author:        Parham Alvani <parham.alvani@gmail.com>
 * |
 * | Creation Date: 23-10-2017
 * |
 * | File Name:     linesearch.go
 * +===============================================
 */

package optimize

// State represents an state in the optimization procedure.
type State struct {
	X        []float64
	F        float64
	Gradient []float64
}

// NextDirectioner implements a strategy for computing a new line search
// direction at each major iteration. Typically, a NextDirectioner will be
// used in conjunction with LinesearchMethod for performing gradient-based
// optimization through sequential line searches.
type NextDirectioner interface {
	// InitDirection initializes the NextDirectioner at the given starting location,
	// putting the initial direction in place into dir, and returning the initial
	// step size. InitDirection must not modify State.
	InitDirection(loc *State, dir []float64) (step float64)

	// NextDirection updates the search direction and step size. Location is
	// the location seen at the conclusion of the most recent linesearch. The
	// next search direction is put in place into dir, and the next step size
	// is returned. NextDirection must not modify State.
	NextDirection(loc *State, dir []float64) (step float64)
}

// LinesearchMethod represents an abstract optimization method in which a
// function is optimized through successive line search optimizations.
type LinesearchMethod struct {
	// NextDirectioner specifies the search direction of each linesearch (p).
	NextDirectioner NextDirectioner
	// Linesearcher performs a linesearch along the search direction.
	Linesearcher Linesearcher

	x   []float64 // Starting point for the current iteration.
	dir []float64 // Search direction for the current iteration.

	first     bool      // Indicator of the first iteration.
	nextMajor bool      // Indicates that MajorIteration must be commanded at the next call to Iterate.
	eval      Operation // Indicator of valid fields in Location.

	lastStep float64   // Step taken from x in the previous call to Iterate.
	lastOp   Operation // Operation returned from the previous call to Iterate.
}
