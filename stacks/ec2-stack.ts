import { Construct } from "constructs";
import { TerraformStack, TerraformOutput, Fn } from "cdktf";
import { AwsProvider } from "@cdktf/provider-aws/lib/provider";
import { Instance } from "@cdktf/provider-aws/lib/instance";
import { SecurityGroup } from "@cdktf/provider-aws/lib/security-group";
import { DataAwsSsmParameter } from "@cdktf/provider-aws/lib/data-aws-ssm-parameter";
import * as path from "path";
import * as dotenv from "dotenv";
dotenv.config();
export class Ec2Stack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new AwsProvider(this, "aws", {
      region: "ap-south-1",
    });

    const ubuntuAmi = new DataAwsSsmParameter(this, "ubuntuAmi", {
      name: "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id",
    });

    const sg = new SecurityGroup(this, "webSg", {
      name: "web_sg_terraform",
      description: "Allow SSH, HTTP, and HTTPS traffic",
      ingress: [
        { fromPort: 22, toPort: 22, protocol: "tcp", cidrBlocks: ["0.0.0.0/0"] },
        { fromPort: 80, toPort: 80, protocol: "tcp", cidrBlocks: ["0.0.0.0/0"] },
        { fromPort: 443, toPort: 443, protocol: "tcp", cidrBlocks: ["0.0.0.0/0"] },
      ],
      egress: [{ fromPort: 0, toPort: 0, protocol: "-1", cidrBlocks: ["0.0.0.0/0"] }],
    });

 
    const deployScriptPath = path
      .resolve(__dirname, "../scripts/deploy.sh")
      .replace(/\\/g, "/");

    const domains = ["node3.divyanshutiwari.site", "node4.divyanshutiwari.site"];
    const githubRepo = "divyanshutiwari13/nextjs-terraform";
    const githubPat = process.env.GITHUB_PAT || "";
  
    const email = "test@gmail.com";

    const nodeInstances = domains.map((domain, index) => {
      return new Instance(this, `node${index + 1}`, {
        ami: ubuntuAmi.value,
        instanceType: "t2.micro",
        keyName: "terraform-key",
        vpcSecurityGroupIds: [sg.id],
        userData: Fn.templatefile(deployScriptPath, {
          domain,
          github_repo: githubRepo,
          github_pat: githubPat,
          email,
        }),
        rootBlockDevice: {
          volumeSize: 10,
        },
        tags: { Name: `node${index + 1}` },
      });
    });

    new TerraformOutput(this, "node_ips", {
      value: {
        node3: nodeInstances[0].publicIp,
        node4: nodeInstances[1].publicIp,
      },
    });
  }
}
