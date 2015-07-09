# Why hxbolts

Source code for http://blog.zame-dev.org/why-hxbolts/

# How to compile

Install `zame-haxe-miscutils`:

```
haxelib git zame-miscutils https://github.com/restorer/zame-haxe-miscutils.git
```

than

```
lime test flash -D<specify_compilation_flag>
```

or

```
lime test neko -D<specify_compilation_flag>
```

# Compilation flags

  - `-Dtest_promhx` - compile tests for `promhx` library
  - `-Dtest_thxpromise` - compile tests for `thx.promise` library
  - `-Dtest_task` - compile tests for `task` library
  - `-Dtest_continuation` - compile tests for `continuation` library
  - `-Dtest_async` - compile tests for `async` library
  - `-Dtest_hextflow` - compile tests for `hext-flow` library
  - `-Dtest_hxbolts` - compile tests for `hxbolts library`
