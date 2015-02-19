
""""""""""""""""""""""""""""""""""""""""
" BlxVimrc
" auth:     brambles
" email:    qjnight@gmail.com
" date:     2015-2-18
"
" desc:
"
"   这个文件不需要动，这里仅仅就是一个模
"   块加载器而已啦！如果需要动的话可以自
"   己写一个模块啥的。
"
"   模块定义的方法：
"       1.在modules目录下新建一个<my_module>.vimrc 的文件。
"
"       2.声明一个需要注册的函数。
"           function MyModule()
"               " 随便干点啥
"           endfunction
"
"       3.最后注册函数。
"           Define(模块名, 依赖的模块列表, 要注册的函数)
"           call Define('MyModule', ['base', 'bundle'], function('MyModule'))

let s:modules_define = {}
let s:modules_require = {}
let s:base = fnamemodify(resolve(expand('<sfile>:p')), ':h')

" 声明模块定义函数 Define
function! g:Define(name, require, define)
    if has_key(s:modules_define, a:name)
        echom 'Module Cannot Redefine!'
        return
    endif

    if a:name == ''
        echom 'Module Cannot Define By An Empty Name!'
        return
    endif

    let s:modules_require[a:name]=a:require
    let s:modules_define[a:name]=a:define
endfunction

" 声明模块加载的函数　Load
function! g:Load(module_name)
    if !has_key(s:modules_define, a:module_name)
        echom 'Module not define:' . a:module_name
        return
    endif

    let l:Module = s:modules_define[a:module_name]
    call l:Module()
endfunction

" 加载modules目录下所有模块的定义
for i in split(globpath(s:base.'/modules','*.vimrc'))
    exec 'source' . i
    unlet i
endfor

" 模块拓扑排序函数
function! s:TopSort(require_dict)

    " 弹出0入度的节点
    function! PopNode(require_list)

        let l:module = ''

        " 找到一个入度为0的节点
        for i in range(0, len(a:require_list) - 1)

            let m = a:require_list[i]
            if empty(m[1])
                let l:module = m[0]
                call remove(a:require_list, i)
                break
            endif

        endfor

        " 找不到入度为0的节点时直接返回，进行错误处理
        if l:module == ''
            return l:module
        endif

        " 将所有依赖它的节点依赖删除
        for i in range(0, len(a:require_list) - 1)

            let m = a:require_list[i]
            let r = index(m[1], l:module)
            if r >= 0
                call remove(m[1], r)
            endif

        endfor

        " 弹出当前节点
        return l:module
    endfunction

    let l:require_list = items(deepcopy(a:require_dict))
    let l:sorted_list = []

    while !empty(l:require_list)
        let l:module = PopNode(l:require_list)
        if l:module == ''
            echom 'Load Error:' . join(l:require_list, ', ')
            break
        endif
        call add(l:sorted_list, l:module)
    endwhile

    return l:sorted_list
endfunction

" 加载化所有模块
let s:modules_load = s:TopSort(s:modules_require)
for module in s:modules_load
    call g:Load(module)
endfor

" End
""""""""""""""""""""""""""""""""""""""""
