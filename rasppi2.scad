/*  RASPBERRY PI2 case
-- Parametric as below
-- Uses a set of measurements for box cutouts for devices
-- Rounded corners
*/
/* Rasberry Pi2 box (should fit B+ as well)
How it works:
    Make a rounded box
    Subtract the interior 
    Enlarge the devices so they protrude then subtract them.
    Slice top and bottom halves.
    Add lugs, holes and stand offs
*/

board = [85, 56 , 1.3 ];  //dimension of rasp pi
t     = 1.40;             //Thickness of rasp pi board
p     = 1.5;              //Thickness of plastic case
g     = 2;                //gap around board
$fn   = 12;               //roundness of rendering
rb    = 4;                //roundness of box
huge  = 200;              // for drilling out holes etc 
stand_off = 3;            //raise board above bottom plastic
box   = board + [7 , 7, 20];  //outside dimensions of our case
bh    = 10;               //Where to slice box
d = 3.5;                  //displacement of hole from edge  
eps = 0.01;               //a very tiny value
/*
Actual device sizes and positions (some already extend over edge of board)
most of these numbers are measurements or off spec sheet
NOTE KEEPING TRACK OF COORDINATE SYSTEMS IS CRITICAL
These are measured  coordinates with zero point at BOTTOM lefthand corner of board

device = [[position of device],[device size],[adjust hole position], [enlarge device for hole]]
*/ 

micro =  [[6.5  ,-1.5 ,0] ,[8    ,6     , 3   ] ,[-1, -10,    0] , [2,   4,  2  ]];
hdmi  =  [[24.4 ,-2   ,0] ,[15.2 ,12    , 7.9 ] ,[0,  -10,    0] , [0,  10,  0  ]];
camera=  [[43   ,0    ,0] ,[4    ,22.4  , 7   ] ,[0,    0,    0] , [0,   0, 10  ]];
audio =  [[50.4 ,-2   ,0] ,[6.2  ,14.5  , 6.4 ] ,[0,  -10,    0] , [0,  10,  0  ]];
ether =  [[65.5 ,2    ,0] ,[21.2 ,15.9  , 15  ] ,[0,   -2,    0] , [5,   4, 10  ]];
//widen usb and ether so we dont have a thin vertical strip of weak plastic
usb1  =  [[70   ,21.4 ,0] ,[17.4 ,15.3  , 17.4] ,[0,   -2,    0] , [0,   4, 10  ]];
usb2  =  [[70   ,39   ,0] ,[17.4 ,15.3  , 17.4] ,[0,   -2,    0] , [0,   4, 10  ]];
gpio  =  [[7.2  ,50   ,0] ,[50   ,5.1   , 9   ] ,[0,    0,    0] , [0,   0, 10  ]];
display= [[1.5  ,17   ,0] ,[3.9  ,22.3  , 6   ] ,[0,    0,    0] , [0,   0, 10  ]];
//SD is below the board so needs to drop a fair bit to give access to the card
SD    =  [[-3  ,19.5 ,-2.5] ,[14   ,17  , 2.5 ] ,[-16,   0,    -4] , [6,   0,  4  ]];
// make a list so we can handle our devices as a group 
echidna = [micro,hdmi,camera,audio,ether,usb1,usb2,gpio,display,SD];  

shift =[p+g,p+g,p+stand_off];  //plastic + gap at edge and height of screw pad
holes =  [[p+g+d, p+g+d], [65, p+g+d], [65, 56], [p+g+d, 56]]  ;
toplugs =[
          [[box[0]*4/5,p+p/2, box[2]-bh],[90,0,0]],
          [[box[0]*4/5,box[1]-p-p/2,bh], [90,0,0]],
          [[p+p/2,box[1]*3/4-p-p,bh],[0,90,0]],
          [[p+p/2,box[1]/4-p-p,bh],[0,90,0]]
          ];        
 bottomlug =[[-p/2,box[1]/2,bh],[0,90,0]];

//Utility module to make a solid box with rounded corners
module hull_build(box,r){
    //spheres at the corners of a box and run hull over it
    x = box  - 2 * [r,r,r];
    difference(){
    hull(){
        for (i=[0:1]){
            for (j=[0:1]) {
                for (k=[0:1]){
                        translate([i*x[0],j*x[1],k*x[2]]+[r,r,r]) //move up r because we moved box up
                            sphere(r);
                            }            
                        }   
                    }  
              }   
         }  
}


module complete_box(){
    embiggen = [2,2,2]; // make holes 1mm bigger all round
    //substract devices out of our case
    difference(){
        hull_build(box,rb); //outer shell
        translate([p,p,p])hull_build(box-[p+p,p+p,p+p],rb);  //smaller box(interior)
    //move, embiggen then subtract
        for (i=echidna) {
            translate(i[0] + i[2] + shift -embiggen/2) 
                    cube(i[1]+ i[3] + embiggen);
                        }
                }
   }
   
module stand_off() {
    difference(){
        union(){
            children();  // this will the complete_box
            for (q=holes){
                translate([q[0],q[1],p+3/2]) 
                    cylinder(d1=9,d2=7,h=3,center=true); 
            }

        }  
        //put in eps to stop an error warning
        for (q=holes){
        translate([q[0]+eps,q[1]+eps,3/2]){
            cylinder(d=3.5,h=huge,center=true);
                cylinder(d=8,h=3,center=true,$fn=6);  
        }
    }
    }
}

module top_holes(){
    difference(){
        union(){
            children();  //this will be complete_box
            for (q=holes){
            translate([q[0],q[1],box[2]-p-p]) 
                    cylinder(d=3+p+p,h=3,center=true); //reinforcing plastic around top hole
            }
        }  
        for (q=holes){
        translate([q[0],q[1],3/2]){
           cylinder(d=3.5,h=huge,center=true);
        }
    }
    }
}


module bottom(){
difference() {
        //Add standoff and drill holes at same time
        stand_off(holes) complete_box();
        translate([-20,-20,bh])cube(huge);  //chop the top off
    }
    
    //put a lug at the end to stabilise the lid before screwing
        translate(bottomlug[0])
            rotate(bottomlug[1])
                cylinder(d=4,h=p,center=true);
}

module top(){

    difference(){
    intersection() {
        top_holes(holes)complete_box();  
        translate([-5,-11,bh])cube(huge);   //chop the bottom (note use of intersection)
        }
     }
     
     //Add 2 lugs at the end and one on each side [[position,rotation],..]
     for (lug = toplugs) {
            translate(lug[0]) 
                    rotate(lug[1]) 
                            cylinder(d=4,h=p,center=true);
        }
} 

//complete_box();
bottom();
//flip it over to print and move it to print
//translate([box[0],0,box[2]])rotate([0,180,0])top();  