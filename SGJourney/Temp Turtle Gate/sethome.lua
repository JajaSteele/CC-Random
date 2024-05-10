local automata = peripheral.find("endAutomata")

automata.savePoint("home")

print(textutils.serialize(automata.points()))