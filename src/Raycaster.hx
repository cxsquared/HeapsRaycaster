import hxd.Key;
import h2d.col.Point;
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
        [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,7,7,7,7,7,7,7,7],
        [4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7],
        [4,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7],
        [4,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7],
        [4,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,0,0,0,0,0,7],
        [4,0,4,0,0,0,0,5,5,5,5,5,5,5,5,5,7,7,0,7,7,7,7,7],
        [4,0,5,0,0,0,0,5,0,5,0,5,0,5,0,5,7,0,0,0,7,7,7,1],
        [4,0,6,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8],
        [4,0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,7,7,1],
        [4,0,8,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,0,0,0,8],
        [4,0,0,0,0,0,0,5,0,0,0,0,0,0,0,5,7,0,0,0,7,7,7,1],
        [4,0,0,0,0,0,0,5,5,5,5,0,5,5,5,5,7,7,7,7,7,7,7,1],
        [6,6,6,6,6,6,6,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6],
        [8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4],
        [6,6,6,6,6,6,0,6,6,6,6,0,6,6,6,6,6,6,6,6,6,6,6,6],
        [4,4,4,4,4,4,0,4,4,4,6,0,6,2,2,2,2,2,2,2,3,3,3,3],
        [4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2],
        [4,0,0,0,0,0,0,0,0,0,0,0,6,2,0,0,5,0,0,2,0,0,0,2],
        [4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2],
        [4,0,6,0,6,0,0,0,0,4,6,0,0,0,0,0,5,0,0,0,0,0,0,2],
        [4,0,0,5,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,2,0,2,2],
        [4,0,6,0,6,0,0,0,0,4,6,0,6,2,0,0,5,0,0,2,0,0,0,2],
        [4,0,0,0,0,0,0,0,0,4,6,0,6,2,0,0,0,0,0,2,0,0,0,2],
        [4,4,4,4,4,4,4,4,4,4,1,1,1,2,2,2,2,2,2,3,3,3,3,3]
    ];

    var screenWidth:Int;
    var screenHeight:Int;

    var pos = new Point(22, 21); // start position
    var dir = new Point(-1, 0); // dir
    var plane = new Point(0, .66); // camera plane

    var time:Float = 0;
    var oldTime:Float = 0;

    var textures = new Array<Pixels>();
    var texWidth:Int = 64;
    var texHeight:Int = 64;

    public function new (parent:Scene) {
        super(parent);

        screenWidth = parent.width;
        screenHeight = parent.height;

        var w = screenWidth;
        var h = screenHeight;
        var len = w * h;

        bytes = Bytes.alloc(len * 4);
        pixels = new Pixels(w, h, bytes, ARGB);

        for(i in 0...8) {
            textures[i] = new Pixels(texWidth, texHeight, Bytes.alloc(texWidth * texHeight * 4), ARGB);
        }

        #if 0
        for (x in 0...texWidth) {
            for (y in 0...texHeight) {
                var xorColor:UInt = Std.int((x * 256 / texWidth)) ^ Std.int((y * 256 / texHeight));
                var xColor:UInt = Std.int(x * 256 / texWidth);
                var yColor:UInt = Std.int(y * 256 / texHeight);
                var xyColor:UInt = Std.int(y * 128 / texHeight + x * 128 / texWidth);
                textures[0].setPixel(x, y, (65536 * 254 * cast(x != y && x != texWidth - y)) | 0xFF << 24); // flat red texture with black cross
                textures[1].setPixel(x, y, (xyColor + 256 * xyColor + 65536 * xyColor) | 0xFF << 24); // sloped greyscale
                textures[2].setPixel(x, y, (256 * xyColor + 65536 * xyColor) | 0xFF << 24); // sloped yellow gradient
                textures[3].setPixel(x, y, (xorColor + 256 * xorColor + 65536 * xorColor) | 0xFF << 24); //xor greyscale
                textures[4].setPixel(x, y, (256 * xorColor) | 0xFF << 24); // xor  
                textures[5].setPixel(x, y, (65536 * 192 * cast(x % 16 == 0 && y % 16 == 0)) | 0xFF << 24); // red ricks
                textures[6].setPixel(x, y, (65536 * yColor) | 0xFF << 24); // red gradient
                textures[7].setPixel(x, y, (128 + 256 * 128 + 65536 * 128) | 0xFF << 24); // flat grey texture
            }
        }
        #else
        var tiles = hxd.Res.wolftextures.getPixels(ARGB);    
        textures[0] = tiles.sub(0, 0, texWidth, texHeight);
        textures[1] = tiles.sub(1 * texWidth, 0, texWidth, texHeight);
        textures[2] = tiles.sub(2 * texWidth, 0, texWidth, texHeight);
        textures[3] = tiles.sub(3 * texWidth, 0, texWidth, texHeight);
        textures[4] = tiles.sub(4 * texWidth, 0, texWidth, texHeight);
        textures[5] = tiles.sub(5 * texWidth, 0, texWidth, texHeight);
        textures[6] = tiles.sub(6 * texWidth, 0, texWidth, texHeight);
        textures[7] = tiles.sub(7 * texWidth, 0, texWidth, texHeight);
        #end
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

            // texture calculations
            var texNum:Int = worldMap[Std.int(map.x)][Std.int(map.y)] - 1;

            var wallX:Float; // where exactly the wall was hit
            if (side == 0) wallX = pos.y + perpWallDist * rayDirY;
            else wallX = pos.x + perpWallDist * rayDirX;
            wallX -= Math.floor(wallX);

            // x coord on the texture
            var texX = Std.int(wallX * texWidth);
            if (side == 0 && rayDirX > 0) texX = texWidth - texX - 1;
            if (side == 1 && rayDirY < 0) texX = texWidth - texX - 1;

            var step = 1.0 * texHeight / lineHeight;
            // starting tex Coord
            var texPos = (drawStart - screenHeight / 2 + lineHeight / 2) * step;

            // todo use pixels function to blit
            for(y in drawStart...drawEnd) {
                var texY = Std.int(texPos) & (texHeight - 1);
                texPos += step;
                var color = textures[texNum].getPixel(texX, texY); 
                //make color darker for y-sides: R, G and B byte each divided through two with a "shift" and an "and"
                if (side == 1) color = (color >> 1) & 8355711;
                color = color | 0xff << 24;

                pixels.setPixel(x, y, color);
            }
        }

        emitTile(ctx, Tile.fromPixels(pixels));
    }
}