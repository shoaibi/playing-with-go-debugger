package main

import (
	"fmt"
)

func main() {
	fmt.Println("No variables")
	i := 10

	fmt.Println("First line ", i)
	i++
	fmt.Println("Second line ", i)
	i--
	fmt.Println("Third line ", i)

	for j := 0; j < 20; j++ {
		fmt.Println("J is : ", j)
	}
}
