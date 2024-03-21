# Two Agent Copilot<br/>with Agent Proxy

This is a sample of two Assistants being used as agents in a complex Copilot solution.

## Diagram

![Two agent Assistant Diagram](images/proxy-two-agent-diagram.png)

## Agents

- **Sales Agent:** It is implemented with an Assistants API that can perform calculations and can provide the user information customer, sellers, customer orders, and inventory.
- **Trading Agent:** It is implemented with an Assistant API with function calling and code interpreter to get the latest stock prices and can provide the user with up to date prices and perform portfolio calculations.

## Orchestration

- **Agent Proxy:** This agent coordinates which agent to call depending on user's intent.

## Possible messages handling options

1. No handling: a la LLM model
2. Manual handling: user write logic to coordinate messages between two agent
3. Hybrid: One agent keeps state the other just used as LLM
