#include <unordered_map>
#include <string>

using namespace std;

typedef struct {
    char* name;
    int type;
    int registerNumber;
} Variable;

unordered_map<char*, Variable, > symbols;

void insert2symbols(char* name, int type, int registerNumber) {
}

