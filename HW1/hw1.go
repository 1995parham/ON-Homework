/*
 * +===============================================
 * | Author:        Parham Alvani <parham.alvani@gmail.com>
 * |
 * | Creation Date: 23-10-2017
 * |
 * | File Name:     linesearch.go
 * +===============================================
 */

package main

import (
	"fmt"
	"math"
)

type variable struct {
	x1, x2, x3 float64
}

func main() {
	// Starting point
	var x0 variable
	fmt.Scanf("%f %f %f", &x0.x1, &x0.x2, &x0.x3)

	var alpha, beta, c float64
	fmt.Scanf("%f %f %f", &alpha, &beta, &c)
}

func f(x variable) float64 {
	return -x.x1 - x.x2 - x.x3
}

func gf(x variable) variable {
	return variable{
		x1: 0,
		x2: 0,
		x3: 0,
	}
}

func norm(x variable) float64 {
	return math.Sqrt(x.x1*x.x1 + x.x2*x.x2 + x.x3*x.x3)
}
