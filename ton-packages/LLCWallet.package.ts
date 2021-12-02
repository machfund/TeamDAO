export default {"abi":{"ABI version":2,"header":["time","expire"],"functions":[{"name":"constructor","inputs":[{"name":"custodians","type":"map(address,uint32)"},{"name":"distributionFee","type":"uint128"}],"outputs":[]},{"name":"getExt","inputs":[],"outputs":[{"name":"custodians","type":"map(address,uint32)"}]},{"name":"createProposal","inputs":[{"name":"newCustodians","type":"map(address,uint32)"}],"outputs":[]},{"name":"vote","inputs":[{"name":"currentProposalIndex","type":"uint32"},{"name":"value","type":"bool"}],"outputs":[]},{"name":"getProposals","inputs":[],"outputs":[{"components":[{"name":"creator","type":"address"},{"name":"oldCustodians","type":"map(address,uint32)"},{"name":"newCustodians","type":"map(address,uint32)"},{"name":"votesFor","type":"uint128"},{"name":"votesAgainst","type":"uint128"},{"name":"votesTotal","type":"uint128"},{"name":"votesNeeded","type":"uint128"},{"name":"start","type":"uint32"},{"name":"end","type":"uint32"}],"name":"value0","type":"tuple[]"}]},{"name":"getVotes","inputs":[],"outputs":[{"name":"value0","type":"map(uint32,map(address,bool))"}]}],"data":[{"key":1,"name":"_id","type":"uint32"}],"events":[]},"image":"te6ccgECNwEACfcAAgE0AwEBAcACAEPQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAgaK2zU2BAQkiu1TIOMDIMD/4wIgwP7jAvILMwYFNQPWjQhgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE+Gkh2zzTAAGfgQIA1xgg+QFY+EL5EPKo3tM/AfhDIbnytCD4I4ED6KiCCBt3QKC58rT4Y9MfAfgjvPK50x8B2zz4R26OgN4dCAcEPiLQ0wP6QDD4aak4ANwhxwAgjoDf4wIB2zz4R26OgN4uLAgHAQZb2zwwAiggghA8NLozu+MCIIIQfDOUxrvjAhQJAiggghBe207ruuMCIIIQfDOUxrrjAgsKAngw+EJu4wDR+Ewhjigj0NMB+kAwMcjPhyDOjQQAAAAAAAAAAAAAAAAPwzlMaM8W9ADJcPsAkTDi2zx/+GcyMQT8MPhCbuMA0x/SANH4SY0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABMcF8tBk+Eki+EpvEYAg9A/ystDbPG8RgQEL9AogkTHe8uBkaKb+YIIQF9eEAL7y4GX4IyL4Sm8RgCD0D/Ky0Ns8bxi58uBoIfhOXIAgMioqDASI9A6S9AWRbeIjyMoA+ElYgQEL9FFVIMj0AFmAIPRD+G4wII6AjoDi+EpvIiMBUxK58rJcgCD0D/Ky0Ns8IG8VpLV/b1UTEioNBFrbPMlZgCD0F28C+Goh+EpvEYAg9A/ystDbPG8TIvhKbxGAIPQP8rLQ2zxvFrorKioOBBqOgI6A4ts8W9s8f/hnEQ8kMQNIIfhKbxGAIPQP8rLQ2zxvFCL4Sm8RgCD0D/Ky0Ns8bxa6joDeKioQApAh+E6AIPRbMPhu+EpvIiMBUxK58rL4Sm8QpbX/+EpvEYAg9A/ystDbPNs8yVmAIPQXbwIg+GpvIiHytgGlIFiAIPRbMG8C+GoqKwEGIds8KAJS+EpvIiMBUxK58rJcgCD0D/Ky0Ns8IG8UpLV/b1TbPMlZgCD0F28C+GoqKwJS+EpvIiMBUxK58rJcgCD0D/Ky0Ns8IG8TpLV/b1PbPMlZgCD0F28C+GoqKwRQIIIQBv/xqbrjAiCCECVolpO64wIgghAuFE9+uuMCIIIQPDS6M7rjAiAXFhUCeDD4Qm7jANH4TiGOKCPQ0wH6QDAxyM+HIM6NBAAAAAAAAAAAAAAAAAvDS6M4zxb0AMlw+wCRMOLbPH/4ZzIxAoQw+EJu4wDR+Eohji4j0NMB+kAwMcjPhyDOjQQAAAAAAAAAAAAAAAAK4UT36M8WAW8iAssf9ADJcPsAkTDi2zx/+GcyMQTCMPhCbuMA+Ebyc3/4ZvQE03/R+EGIyM+OK2zWzM7J2zwgbvLQZF8gbvJ/0PpAMCD4SccF8uBkII0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABMcF8tBkIx02GhgCLNs8+FOZIPhwI/hsIvhx3l8E2zx/+GcZMQCEcCGBAQv0gm+hlgHXCx9vAt6TIG6zjiBfIG7yf28iUzCgtR80UxSBAQv0dG+hlgHXCx9vAt4zW+gwwGTy4GUwf/hzAhjQIIs4rbNYxwWKiuIbHAEK103Q2zwcAELXTNCLL0pA1yb0BDHTCTGLL0oY1yYg10rCAZLXTZIwbeICFu1E0NdJwgGKjoDiMh4B/HDtRND0BXBtbwL4ao0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABG1tcF9Qbwn4a234bHD4bW34bnEhgED0DpPXCx+RcOL4b40IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABPhwcPhxcPhycB8AMvhzgED0DvK91wv/+GJw+GNw+GZx+HJw+HMC0jD4Qm7jAPQE0fhJjQhgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAExwXy0GT4SfhMgQEL9AogkTHe8uBkaKb+YIIQF9eEAL7y4GX4TIEBC/SCb6GWAdcLH28C3nBwkyJuszIhAfqOJlMibvJ/byIjpLUfNFMgoLUfMyH4TIEBC/R0b6GWAdcLH28C3jVb6CDAZPLgZXAiqTgAwACXMCGrAKS1H5cwIaS1H6sA4vhL+ElvUCD4a/hMb1Eg+Gslb1Ig+Gtxb1Mg+Gtwb1Qg+Gtxb1Ug+Gshb1Yg+Gv4I29X+Gv4IyIE/oID9ICgtR/4SwFvWPhr+Er4S9s8yQFvIiGkVSCAIPQXbwL4an/4TvhKbxCltR8BXIAg9A6S9AWRbeL4SQFVA8jKAFmBAQv0Qcj0AFmAIPRD+G74Sm8QpbUf+EpvEYAg9A/ystDbPG8T+EpvEKW1H/hKbxGAIPQP8rLQ2zxvFrorKiojAxiOgN7bPF8F2zx/+GcnJDEBGHCWIPhKbxC5joDoMCUCLvgjIfhKbxGAIPQP8rLQ2zxvGLyOgN6kKiYCfPhKbyIiAVMSufKy+EpvEKW1//hKbxGAIPQP8rLQ2zzbPMlZgCD0F28CIPhqbyIh8rYBpSBYgCD0WzBvAvhqKisBEvhKbxCltR/bPCgErCD4Sm8RgCD0D/Ky0Ns8bxMh+EpvEYAg9A/ystDbPG8WuvLgaW34bCD4Sm8RgCD0D/Ky0Ns8bxL4bPhKbyIiAVMSufKy+EpvEKW1//hKbxGAIPQP8rLQKioqKQJU2zzbPMlZgCD0F28CIPhqbyIh8rYBpSBYgCD0WzBvAvhq+E6AIPRbMPhuKisAWvpA9AT0BNN/03/Tf9cNf5XU0dDTf9/XDR+V1NHQ0x/f1w0fldTR0NMf39FvCQA0bylecMjO9AD0AMt/y3/Lf1UgyMt/yx/LH80C2vhCbuMAaKb+YPhRqLV/gQPoqQT4TIEBC/SCb6GWAdcLH28C3pMgbrOOPl8gbvJ/byJopv5gJKG1fyGotX+AZKkEUwLIz4UIzgH6AoBrz0DJc/sAIvhMgQEL9HRvoZYB1wsfbwLeNF8D6PhRwgAyLQEyjhMh+FDIz4UIzgH6AoBrz0DJc/sA3lvbPDEBIDAh1w0fjoDfIcAAIJJsId4vAQow2zzyADACDvhCbuMA2zwyMQCy+FP4UvhR+FD4T/hO+E34TPhL+Er4RvhD+ELIy//LP8oAAW8iAssf9AABbylegM70APQAVdDIy3/Lf8t/y3/LH8sf9ADLH/QAyx9VMMjOy3/LD8oAzc3J7VQAsu1E0NP/0z/SANMf9ARZbwIB+kD0BPQE1NHQ03/Tf9N/03/TH9MfVYBvCQH0BNMf9ATTH9TR0PpA03/TD9IA0fhz+HL4cfhw+G/4bvht+Gz4a/hq+Gb4Y/hiAgr0pCD0oTU0ABRzb2wgMC40Ny4wAAAADCD4Ye0e2Q=="}