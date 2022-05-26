#include <math.h>
#include <stdio.h>
main()

{

FILE *mapfile;

double x;
double y;
double xpos;
double ypos;
int a;

mapfile = fopen("TUNNEL.DAT", "wb");
if (!mapfile)
{
printf("Couldn't create output file.");
return 0;
}

for (y=100; y>0; y--)
{
for (x=-160; x<160; x++)
{
xpos = atan2(y, x);
a = ((xpos*256) / (M_PI*2));
fwrite(&a, 1, 1, mapfile);

ypos = sqrt((x*x) + (y*y));
ypos = 2000 / ypos;
a = ((ypos/189) * 256);
fwrite(&a, 1, 1, mapfile);
}
}

for (y=1; y<101; y++)
{
for (x=-160; x<160; x++)
{
xpos = atan2(y, x);
a = ((xpos*256) / (M_PI*2));
fwrite(&a, 1, 1, mapfile);

ypos = sqrt((x*x) + (y*y));
ypos = 2000 / ypos;
a = ((ypos/189) * 256);
fwrite(&a, 1, 1, mapfile);
}
}

fclose(mapfile);
return 0;

}