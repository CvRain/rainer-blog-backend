import { Elysia } from "elysia";
import { swagger } from "@elysiajs/swagger"

class Note{
  constructor(public data:string[] = ['hello note']){

  }
}

class Response{
  constructor(public code:number = 200, public message:string = 'success', public data:any = null){

  }
}

const app = new Elysia()
.use(swagger())
.get("/", ({path}) => "Hello Elysia" + path)
.get("/hello", () => "Hello world!")
.post("/hello", () => "Hello world!")
.decorate("note", new Note())
.get("/notes", ({note}) => note.data)
.decorate("response", new Response())
.get("/response", ({response}) => {
  return {
    code: response.code,
    message: response.message,
    data: response.data
  };
})
.listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);
