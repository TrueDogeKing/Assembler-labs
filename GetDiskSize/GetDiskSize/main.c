#include <stdio.h>
#include <stdlib.h>

// Deklaracja funkcji asemblerowej
extern unsigned int rozmiar_dysku(char* dysk);

int main() {
    char dysk[4] = "C:\\";
    unsigned int rozmiar;

    printf("Sprawdzanie rozmiaru dysku %s\n", dysk);

    rozmiar = rozmiar_dysku(dysk);


    printf("\n--- Test z dyskiem D: ---\n");
    char dysk2[4] = "D:\\";
    rozmiar = rozmiar_dysku(dysk2);


    return 0;
}