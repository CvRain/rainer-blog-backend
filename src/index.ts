import { Elysia, t } from "elysia";
import { swagger } from "@elysiajs/swagger"

import { hello } from "./controllers/hello";

const app = new Elysia()
.use(swagger())
.use(hello)
.get("/", ({path}) => "Hello Elysia" + path)

.listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`
);
