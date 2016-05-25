//solution by Wsl_F
#include <bits/stdc++.h>

using namespace std;
#pragma comment(linker, "/STACK:1024000000,1024000000")


typedef long long LL;
typedef unsigned long long uLL;
typedef double dbl;
typedef vector<int> vi;
typedef vector<LL> vL;
typedef vector<string> vs;
typedef pair<int,int> pii;
typedef pair<LL,LL> pLL;

#define mp(x,y)  make_pair((x),(y))
#define pb(x)  push_back(x)
#define sqr(x) ((x)*(x))


int main()
{
    ios_base::sync_with_stdio(0);
    cin.tie(0);
    srand(__rdtsc());
// LL a[110];
// memset(a,0,sizeof(a));

//freopen("input.txt","r",stdin);
    freopen("run.bat","w",stdout);
//cout<<fixed;
//cout<<setprecision(9);

    int numberOfLines= 94176;
    int interval= 20;
    int j= 0;
    int pause_leng= 60;
    int threadNum= 8;

    for (int line= 0; line < numberOfLines; line+= interval)
    {
        cout<<"start ruby match_words.rb input.csv output"<<j<<".txt "<<line<<" "<<interval<<endl;

        j++;

        if ( j % threadNum == 0)
        {
            cout<<"timeout "<<pause_leng<<endl<<endl;
        }
    }

    return 0;
}
