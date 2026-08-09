package trivy

deny[msg] {
    vuln := input.Results[_].Vulnerabilities[_]
    vuln.Severity == "CRITICAL"
    msg := sprintf("CRITICAL vuln: %s in %s (fix: %s)",
        [vuln.VulnerabilityID, vuln.PkgName, vuln.FixedVersion])
}

warn[msg] {
    high_vulns := [v | v := input.Results[_].Vulnerabilities[_]; v.Severity == "HIGH"]
    count(high_vulns) > 10
    msg := sprintf("Too many HIGH vulns: %d (threshold: 10)", [count(high_vulns)])
}
