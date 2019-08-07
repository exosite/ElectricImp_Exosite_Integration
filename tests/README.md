This is a super-summary of: [ElectricImps Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md)

# First
impt auth login 

# One time
```
impt product create --name <test_product>
impt dg create --product <test_product> --name <test_group>
impt device assign --device <device> --dg <test_group>
```

`impt test create --dg \<test_group\> --agent-file tests/MuranoTest.agent.test.nut`

# Run tests
impt test run



