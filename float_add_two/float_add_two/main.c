#include <stdio.h>

extern double add_two(double);

int main() {
    double x = -13002200000.763;
    printf("Result: %f\n", add_two(x));  // Wynik: 5.5
    return 0;
}
