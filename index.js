import {
  EditorState,
  EditorView,
  basicSetup
} from "https://cdn.skypack.dev/@codemirror/basic-setup@0.18.0";

let editor = new EditorView({
  state: EditorState.create({
    extensions: [basicSetup]
  }),
  parent: document.getElementById("code")
});
