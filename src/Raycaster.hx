import hxd.Key;
import hxd.Timer;
import h2d.col.Point;
import hxd.Rand;
import h2d.Tile;
import h2d.Scene;
import haxe.io.Bytes;
import hxd.Pixels;
import h2d.RenderContext;
import h2d.Object;

// https://lodev.org/cgtutor/raycasting.html
class Raycaster extends Object {
    var bytes:Bytes;
    var pixels:Pixels;

    var mapWidth = 24;
    var mapheight = 24;

    var worldMap = [
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
        [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1],
        [1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1],
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    ];

    var screenWidth:Int;
    var screenHeight:Int;

    var pos = new Point(22, 21); // start position
    var dir = new Point(-1, 0); // dir
    var plane = new Point(0, .66); // camera plane

    var time:Float = 0;
    var oldTime:Float = 0;

    public function new (parent:Scene) {
        super(parent);

        screenWidth = parent.width;
        screenHeight = parent.height;

        var w = screenWidth;
        var h = screenHeight;
        var len = w * h;

        bytes = Bytes.alloc(len * 4);
        pixels = new Pixels(w, h, bytes, ARGB);

        var time:Float = 0;
        var oldTime:Float = 0;
    }

    public function update(dt:Float) {
        var moveSpeed = dt * 5.0;
        var rotSpeed = dt * 3.0;

        if (Key.isDown(Key.UP)) {
            if (worldMap[Std.int(pos.x + dir.x * moveSpeed)][Std.int(pos.y)] == 0) pos.x += dir.x * moveSpeed; 
            if (worldMap[Std.int(pos.x)][Std.int(pos.y + dir.y * moveSpeed)] == 0) pos.y += dir.y * moveSpeed; 
        }

        if (Key.isDown(Key.DOWN)) {
            if (worldMap[Std.int(pos.x - dir.x * moveSpeed)][Std.int(pos.y)] == 0) pos.x -= dir.x * moveSpeed; 
            if (worldMap[Std.int(pos.x)][Std.int(pos.y - dir.y * moveSpeed)] == 0) pos.y -= dir.y * moveSpeed; 
        }

        if (Key.isDown(Key.RIGHT)) {
            var oldDirX = dir.x;
            dir.x = dir.x * Math.cos(-rotSpeed) - dir.y * Math.sin(-rotSpeed);
            dir.y = oldDirX * Math.sin(-rotSpeed) + dir.y * Math.cos(-rotSpeed);
            var oldPlaneX = plane.x;
            plane.x = plane.x * Math.cos(-rotSpeed) - plane.y * Math.sin(-rotSpeed);
            plane.y = oldPlaneX * Math.sin(-rotSpeed) + plane.y * Math.cos(-rotSpeed);
        }
        if (Key.isDown(Key.LEFT)) {
            var oldDirX = dir.x;
            dir.x = dir.x * Math.cos(rotSpeed) - dir.y * Math.sin(rotSpeed);
            dir.y = oldDirX * Math.sin(rotSpeed) + dir.y * Math.cos(rotSpeed);
            var oldPlaneX = plane.x;
            plane.x = plane.x * Math.cos(rotSpeed) - plane.y * Math.sin(rotSpeed);
            plane.y = oldPlaneX * Math.sin(rotSpeed) + plane.y * Math.cos(rotSpeed);
        }

    }

    override public function draw( ctx: RenderContext) {
        pixels.clear(0xff000000);

        for (x in 0...screenWidth) {
            var cameraX = 2 * x / screenWidth - 1; // x-coord in camera space
            var rayDirX = dir.x + plane.x * cameraX; 
            var rayDirY = dir.y + plane.y * cameraX; 

            // which box of the map we're in
            var map = new Point(Std.int(pos.x), Std.int(pos.y)); 

            // Length of ray from current position to next x or y-side
            var sideDist = new Point();

            // Length of ray from one x or y side to the next
            var deltaDist = new Point(Math.abs(1 / rayDirX), Math.abs(1 / rayDirY));
            var perpWallDist:Float;

            // what direction to step in x or y direction (+1 or -1)
            var step = new Point();

            var hit:Int = 0; // was there a wall hit
            var side:Int = 0; // was a NS or EW wall hit;


            // calculate step and initial sideDist
            if (rayDirX < 0)
            {
                step.x = -1;
                sideDist.x = (pos.x - map.x) * deltaDist.x;
            } else {
                step.x = 1;
                sideDist.x = (map.x + 1.0 - pos.x) * deltaDist.x;
            }
            if (rayDirY < 0)
            {
                step.y = -1;
                sideDist.y = (pos.y - map.y) * deltaDist.y;
            } else {
                step.y = 1;
                sideDist.y = (map.y + 1.0 - pos.y) * deltaDist.y;
            }

            // DDA
            while (hit == 0) {
                // jump to next map square, OR in x-dir, OR in y-dir
                if (sideDist.x < sideDist.y) {
                    sideDist.x += deltaDist.x;
                    map.x += step.x;
                    side = 0;
                } else {
                    sideDist.y += deltaDist.y;
                    map.y += step.y;
                    side = 1;
                }

                //Check if ray has hit a wall
                if (worldMap[Std.int(map.x)][Std.int(map.y)] > 0) hit = 1;
            }

            //Calculate distance projected on camera direction (Euclidean distance will give fisheye effect!)
            if (side == 0) perpWallDist = (map.x - pos.x + (1 - step.x) / 2) / rayDirX; 
            else perpWallDist = (map.y - pos.y + (1 - step.y) / 2) / rayDirY;

            // calculate height of line to draw on screen
            var lineHeight = Std.int(screenHeight/perpWallDist);

            // calculate lowest and highest pixel to fill in current strip
            var drawStart = Std.int(-lineHeight / 2 + screenHeight / 2);
            if (drawStart < 0 ) drawStart = 0;
            var drawEnd = Std.int(lineHeight / 2 + screenHeight / 2);
            if (drawEnd >= screenHeight) drawEnd = screenHeight - 1;

            var color:Int;
            switch(worldMap[Std.int(map.x)][Std.int(map.y)]) {
                case 1: color = 0x00ff0000;
                case 2: color = 0x0000ff00;
                case 3: color = 0x000000ff;
                case 4: color = 0x00ffffff;
                case _: color = 0x00e3fc03;
            }

            // give x and y sides different brightness
            if (side == 1) color = Std.int(color / 2);

            color = color | 0xFF << 24;

            for(y in drawStart...drawEnd) {
                pixels.setPixel(x, y, color);
            }

        }

        emitTile(ctx, Tile.fromPixels(pixels));
    }
}