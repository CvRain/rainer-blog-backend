import { Elysia, t } from 'elysia'

class Hello{
    constructor(public data: BaseResponse){

    }
}

export const hello = new Elysia()
    .decorate('hello', (name: string) => `Hello ${name}`)
    .get('/hello', () => {
        const response: BaseResponse = {
            code: 200,
            message: 'Hello World',
            result: '200Ok'
        }
        return response
    })