# hodooi-contracts

This README would normally document whatever steps are necessary to get your application up and running.

### How do I get set up?

- Summary of set up

```
rm -rf node_modules && rm -f package-lock.json
npm i
```

- Configuration
- Dependencies

* Ganache: https://www.trufflesuite.com/ganache

- Database configuration
- How to run tests

* Install ganache first, and run the below command then:
```
npm run ganache-test
```

- Deployment instructions

  For rinkeby network:

```
truffle deploy -f <start> --to <end> --network rinkeby
```

- How to verify the smart contracts

  For rinkeby network:

```
truffle run verify <Contract_ABI_Name> --network rinkeby
```


### Contribution guidelines

- Writing tests
- Code review
- Other guidelines

### Who do I talk to?

- Repo owner or admin
- Other community or team contact
