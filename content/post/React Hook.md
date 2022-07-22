+++
title="React Hook"
date="2022-07-22"
tags=["React", "Hook"]
+++

## 使用 State Hook
**Hook 是什么？** Hook 是一个特殊的函数，它可以让你“钩入” React 的特性。
**什么时候我会用 Hook？** 如果你在编写函数组件并意识到需要向其添加一些 state。
**useState 需要哪些参数？** useState() 方法里面唯一的参数就是初始 state。不同于 class 的是，我们可以按照需要使用数字或字符串对其进行赋值，而不一定是对象。
**useState 方法的返回值是什么？** 返回值为：当前 state 以及更新 state 的函数。
```javascript
import React, { useState } from 'react';

function Example() {
  // 声明一个叫 "count" 的 state 变量
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>You clicked {count} times</p>
      <button onClick={() => setCount(count + 1)}>
        Click me
      </button>
    </div>
  );
}
```
> const [fruit, setFruit] = useState(0);
这种 JavaScript 语法叫[数组解构](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Array_destructuring)。它意味着我们同时创建了 fruit 和 setFruit 两个变量，fruit 的值为 useState 返回的第一个值，setFruit 是返回的第二个值。它等价于下面的代码：

```javascript
 var fruitStateVariable = useState('banana'); // 返回一个有两个元素的数组
 var fruit = fruitStateVariable[0]; // 数组里的第一个值
 var setFruit = fruitStateVariable[1]; // 数组里的第二个值
```
另外，为什么叫 useState 而不叫 createState?
> “Create” 可能不是很准确，因为 state 只在组件首次渲染的时候被创建。在下一次重新渲染时，useState 返回给我们当前的 state。否则它就不是 “state”了！这也是 Hook 的名字_总是_以 use 开头的一个原因。我们将在后面的 [Hook 规则](https://zh-hans.reactjs.org/docs/hooks-rules.html)中了解原因。

## 使用 Effect Hook
**useEffect 做了什么？** 通过使用这个 Hook，你可以**告诉 React 组件需要在渲染后执行某些操作**。React 会保存你传递的函数（我们将它称之为 “effect”），并且在执行 DOM 更新之后调用它。
**useEffect 会在每次渲染后都执行吗？** 是的，默认情况下，它在第一次渲染之后_和_每次更新之后都会执行。
```javascript
import React, { useState, useEffect } from 'react';

function Example() {
  const [count, setCount] = useState(0);
  
  // Similar to componentDidMount and componentDidUpdate:
  useEffect(() => {
    // Update the document title using the browser API
    document.title = `You clicked ${count} times`;
  });
  
  return (
    <div>
        <p>You clicked {count} times</p>
        <button onClick={() => setCount(count + 1)}>
           Click me
        </button>
    </div>
    );
}
```
### 清除effect
之前，我们研究了如何使用不需要清除的副作用，还有一些副作用是需要清除的。例如**订阅外部数据源**。这种情况下，清除工作是非常重要的，可以防止引起内存泄露！现在让我们来比较一下如何用 Class 和 Hook 来实现。
```javascript
import React, { useState, useEffect } from 'react';

function FriendStatus(props) {
  const [isOnline, setIsOnline] = useState(null);

  useEffect(() => {
    function handleStatusChange(status) {
      setIsOnline(status.isOnline);
    }
    ChatAPI.subscribeToFriendStatus(props.friend.id, handleStatusChange);
    // Specify how to clean up after this effect:
    return function cleanup() {
      ChatAPI.unsubscribeFromFriendStatus(props.friend.id, handleStatusChange);
    };
  });

  if (isOnline === null) {
    return 'Loading...';
  }
  return isOnline ? 'Online' : 'Offline';
}
```
**为什么要在 effect 中返回一个函数？** 这是 effect 可选的清除机制。每个 effect 都可以返回一个清除函数。如此可以将添加和移除订阅的逻辑放在一起。
**React 何时清除 effect？** React 会在组件卸载的时候执行清除操作。正如之前学到的，effect 在每次渲染的时候都会执行。这就是为什么 React _会_在执行当前 effect 之前对上一个 effect 进行清除。
### 通过跳过 Effect 进行性能优化
如果某些特定值在两次重渲染之间没有发生变化，你可以通知 React **跳过**对 effect 的调用，只要传递数组作为 useEffect 的第二个可选参数即可：
```javascript
useEffect(() => {
  document.title = `You clicked ${count} times`;
}, [count]); // 仅在 count 更改时更新
```
## Hook 规则
### 1. 只在最顶层使用Hook
**不要在循环，条件或嵌套函数中调用 Hook，** 确保总是在你的 React 函数的最顶层以及任何 return 之前调用他们。
### 2. 只在 React 函数中调用 Hook
**不要在普通的 JavaScript 函数中调用 Hook。**你可以：

- 在 React 的函数组件中调用 Hook。
- 在自定义 Hook 中调用其他 Hook。
### ESLint 插件
我们发布了一个名为 [eslint-plugin-react-hooks](https://www.npmjs.com/package/eslint-plugin-react-hooks) 的 ESLint 插件来强制执行这两条规则。
```javascript
npm install eslint-plugin-react-hooks --save-dev
```
```javascript
// 你的 ESLint 配置
{
  "plugins": [
    // ...
    "react-hooks"
  ],
  "rules": {
    // ...
    "react-hooks/rules-of-hooks": "error", // 检查 Hook 的规则
    "react-hooks/exhaustive-deps": "warn" // 检查 effect 的依赖
  }
}
```
## 自定义 Hook
通过自定义 Hook，可以将组件逻辑提取到可重用的函数中。
### 提取自定义 Hook
当我们想在两个函数之间共享逻辑时，我们会把它提取到第三个函数中。
**自定义 Hook 是一个函数，其名称以 “use” 开头，函数内部可以调用其他的 Hook。**
**自定义 Hook 必须以 “use” 开头吗？**必须如此。这个约定非常重要。不遵循的话，由于无法判断某个函数是否包含对其内部 Hook 的调用，React 将无法自动检查你的 Hook 是否违反了 [Hook 的规则](https://zh-hans.reactjs.org/docs/hooks-rules.html)。
```javascript
import { useState, useEffect } from 'react';

function useFriendStatus(friendID) {
  const [isOnline, setIsOnline] = useState(null);

  useEffect(() => {
    function handleStatusChange(status) {
      setIsOnline(status.isOnline);
    }

    ChatAPI.subscribeToFriendStatus(friendID, handleStatusChange);
    return () => {
      ChatAPI.unsubscribeFromFriendStatus(friendID, handleStatusChange);
    };
  });

  return isOnline;
}
```
### 使用自定义 Hook
```javascript
function FriendStatus(props) {
  const isOnline = useFriendStatus(props.friend.id);

  if (isOnline === null) {
    return 'Loading...';
  }
  return isOnline ? 'Online' : 'Offline';
}
```

**在两个组件中使用相同的 Hook 会共享 state 吗？**不会。自定义 Hook 是一种重用_状态逻辑_的机制，所以每次使用自定义 Hook 时，其中的所有 state 和副作用都是完全隔离的。
**自定义 Hook 如何获取独立的 state？**每次_调用_ Hook，它都会获取独立的 state。
**尽量避免过早地增加抽象逻辑。**既然函数组件能够做的更多，那么代码库中函数组件的代码行数可能会剧增。这属于正常现象 —— **不必立即将它们拆分为 Hook**。但我们仍鼓励你能通过自定义 Hook 寻找可能，以达到简化代码逻辑，解决组件杂乱无章的目的。
## Hook API 索引
### 基础 Hook
#### useState
返回一个 state，以及更新 state 的函数。
```javascript
const [state, setState] = useState(initialState);
```
#### useEffect
该 Hook 接收一个包含命令式、且可能有副作用代码的函数。
```javascript
useEffect(didUpdate);
```
#### useContext
接收一个 context 对象（React.createContext 的返回值）并返回该 context 的当前值。当前的 context 值由上层组件中距离当前组件最近的 <MyContext.Provider> 的 value prop 决定。
当组件上层最近的 <MyContext.Provider> 更新时，该 Hook 会触发重渲染，并使用最新传递给 MyContext provider 的 context value 值。即使祖先使用 [React.memo](https://zh-hans.reactjs.org/docs/react-api.html#reactmemo) 或 [shouldComponentUpdate](https://zh-hans.reactjs.org/docs/react-component.html#shouldcomponentupdate)，也会在组件本身使用 useContext 时重新渲染。
```javascript
const value = useContext(MyContext);
```
### 额外的 Hook
#### useReducer
[useState](https://zh-hans.reactjs.org/docs/hooks-reference.html#usestate) 的替代方案。它接收一个形如 (state, action) => newState 的 reducer，并返回当前的 state 以及与其配套的 dispatch 方法。
```javascript
const [state, dispatch] = useReducer(reducer, initialArg, init);
```
#### useCallback
返回一个 [memoized](https://en.wikipedia.org/wiki/Memoization) 回调函数。
把内联回调函数及依赖项数组作为参数传入 useCallback，它将返回该回调函数的 memoized 版本，该回调函数仅在某个依赖项改变时才会更新。当你把回调函数传递给经过优化的并使用引用相等性去避免非必要渲染（例如 shouldComponentUpdate）的子组件时，它将非常有用。
useCallback(fn, deps) 相当于 useMemo(() => fn, deps)。
```javascript
const memoizedCallback = useCallback(
  () => {
    doSomething(a, b);
  },
  [a, b],
);
```
#### useMemo
返回一个 [memoized](https://en.wikipedia.org/wiki/Memoization) 值。
把“创建”函数和依赖项数组作为参数传入 useMemo，它仅会在某个依赖项改变时才重新计算 memoized 值。这种优化有助于避免在每次渲染时都进行高开销的计算。
**记住，传入 useMemo 的函数会在渲染期间执行。**请不要在这个函数内部执行不应该在渲染期间内执行的操作，诸如副作用这类的操作属于 useEffect 的适用范畴，而不是 useMemo。
如果没有提供依赖项数组，useMemo 在每次渲染时都会计算新的值。
```javascript
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
```
#### useRef
useRef 返回一个可变的 ref 对象，其 .current 属性被初始化为传入的参数（initialValue）。返回的 ref 对象在组件的整个生命周期内持续存在。
```javascript
const refContainer = useRef(initialValue);
```
#### useImperativeHandle
useImperativeHandle 可以让你在使用 ref 时自定义暴露给父组件的实例值。在大多数情况下，应当避免使用 ref 这样的命令式代码。useImperativeHandle 应当与 [forwardRef](https://zh-hans.reactjs.org/docs/react-api.html#reactforwardref) 一起使用：
```javascript
useImperativeHandle(ref, createHandle, [deps])
```
#### useLayoutEffect
**其函数签名与 useEffect 相同，但它会在所有的 DOM 变更之后同步调用 effect**。可以使用它来读取 DOM 布局并同步触发重渲染。在浏览器执行绘制之前，useLayoutEffect 内部的更新计划将被同步刷新。
尽可能使用标准的 useEffect 以避免阻塞视觉更新。
#### useDebugValue
```javascript
useDebugValue(value)
```
useDebugValue 可用于在 React 开发者工具中显示自定义 hook 的标签。
#### useDeferredValue
**useDeferredValue accepts a value and returns a new copy of the value that will defer to more urgent updates. **If the current render is the result of an urgent update, like user input, React will return the previous value and then render the new value after the urgent render has completed.
#### useTransition
Returns a stateful value for the pending state of the transition, and a function to start it.
```javascript
const [isPending, startTransition] = useTransition();
```
#### useId
useId is a hook for generating unique IDs that are stable across the server and client, while avoiding hydration mismatches.
```javascript
const id = useId();
```
### Library Hooks
#### useSyncExternalStore
useSyncExternalStore is a hook recommended for reading and subscribing from external data sources in a way that’s compatible with concurrent rendering features like selective hydration and time slicing.
```javascript
const state = useSyncExternalStore(subscribe, getSnapshot[, getServerSnapshot]);
```
#### useInsertionEffect
The signature is identical to useEffect, but it fires synchronously _before_ all DOM mutations. Use this to inject styles into the DOM before reading layout in [useLayoutEffect](https://zh-hans.reactjs.org/docs/hooks-reference.html#uselayouteffect). Since this hook is limited in scope, this hook does not have access to refs and cannot schedule updates.
```javascript
useInsertionEffect(didUpdate);
```