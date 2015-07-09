package org.sample;

import openfl.display.Sprite;
import org.sample.fake.Runner;

class App extends Sprite {
    public function new() : Void {
        super();

        #if test_promhx
            Runner.run(new TestPromhx());
        #elseif test_thxpromise
            Runner.run(new TestThxPromise());
        #elseif test_hxbolts
            Runner.run(new TestHxbolts());
        #elseif test_task
            Runner.run(new TestTaskTask());
        #elseif test_continuation
            Runner.run(new TestContinuation());
        #elseif test_async
            Runner.run(new TestAsync());
        #elseif test_hextflow
            Runner.run(new TestHextFlow());
        #else
            #error "compile with -Dtest_XXX"
        #end
    }
}
