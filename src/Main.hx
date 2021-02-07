import hxd.Timer;

class Main extends hxd.App {
    var rc:Raycaster;

    override function init() {
        rc = new Raycaster(s2d);
    }

    static function main() {
        hxd.Res.initEmbed();
        new Main();
    }

    override public function update(dt:Float) {
        super.update(dt);

        rc.update(dt);

        trace(Timer.fps());
    }
}