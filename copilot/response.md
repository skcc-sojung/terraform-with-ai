# Try 1
### Prompt
> Write a Terraform script to associate subnets with their respective AWS Route Tables.
> 
> * Associate the `osj-terraform-with-{aq | cp}-pub-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-pub-a
>   - osj-terraform-with-{aq | cp}-pub-c
>
> * Associate the `osj-terraform-with-{aq | cp}-prv-ap-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-prv-ap-a
>   - osj-terraform-with-{aq | cp}-prv-ap-c
>
> * Associate the `osj-terraform-with-{aq | cp}-prv-db-rt` route table with the following subnets:
>   - osj-terraform-with-{aq | cp}-prv-db-a
>   - osj-terraform-with-{aq | cp}-prv-db-c
>
> Use the `aws_route_table_association` resource for each association. If possible, make the code reusable by referencing variables from `variables.tf.`
<br/>

### Response
Here is the Terraform script to associate the subnets with their respective AWS Route Tables. This script assumes that you have defined the necessary variables in `variables.tf`.

```hcl
/* ... */

resource "aws_route_table_association" "public_rt_assoc1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_ap_rt_assoc1" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.private_ap_rt.id
}

resource "aws_route_table_association" "private_ap_rt_assoc2" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.private_ap_rt.id
}

resource "aws_route_table_association" "private_db_rt_assoc1" {
  subnet_id      = aws_subnet.subnet5.id
  route_table_id = aws_route_table.private_db_rt.id
}

resource "aws_route_table_association" "private_db_rt_assoc2" {
  subnet_id      = aws_subnet.subnet6.id
  route_table_id = aws_route_table.private_db_rt.id
}
```