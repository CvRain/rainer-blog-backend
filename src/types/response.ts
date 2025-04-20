class BaseResponse{
    constructor(
        public code: number,
        public message: string,
        public result: string
    ){}
}

class CommonResponse extends BaseResponse{
    constructor(
        public code: number,
        public message: string,
        public result: string,
        public data: any
    ){
        super(code, message, result);
    }
}