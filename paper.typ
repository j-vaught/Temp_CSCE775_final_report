#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Reinforcement Learning for SAM Prompts],
  abstract: [
    We benchmark point selection strategies for single-shot semantic segmentation under a shared frozen DINOv2 plus SAM pipeline on FSS-1000, comparing eleven heuristics, two behavioral-cloning policies of varying expressiveness, and a PPO fine-tune. To make all selectors directly comparable, every prompt coordinate is quantized to a shared $37 times 37$ grid before reaching SAM. Under this unified action space the strongest heuristic, similarity-weighted Farthest Point Sampling at $alpha = 0.75$, reaches $0.768$ mean IoU at $N = 5$; behavioral cloning of a greedy oracle reaches $0.672$; and two reinforcement-learning fine-tunes warm-started from the cloned policy reach $0.864$ at $N = 5$ and $0.866$ at $N = 10$, with absolute gaps of $0.096$ and $0.136$ over the strongest heuristic and $0.193$ and $0.281$ over imitation. The RL policies' per-step trajectories rise through six clicks and then sit on a high plateau, breaking the plateau-and-decline shape that every heuristic and the imitation policy exhibit. On the canonical FSS-1000 one-shot subset disjoint from our training, the same policies reach $0.876$ and $0.875$, surpassing PerSAM and SegGPT and approaching Matcher on the same DINOv2 plus SAM backbone.
  ],
  authors: (
    (
      name: "J.C. Vaught",
      department: [Dept. of Mechanical Engineering],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
    (
      name: "Xeerak Muhammad",
      department: [Dept. of Computer Science],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
    (
      name: "Jacob Whisenant",
      department: [Dept. of Mechanical Engineering],
      organization: [University of South Carolina],
      location: [Columbia, SC, USA],
      email: ""
    ),
  ),
  index-terms: ("single-shot segmentation", "Segment Anything Model", "point prompts", "DINOv2", "FSS-1000", "behavioral cloning", "reinforcement learning", "PPO"),
  bibliography: none,
)

#figure(
  image("figures/representative_examples.pdf", width: 90%),
  caption: [Representative test-set masks at $N = 10$ on three FSS-1000 queries (rows) across four method classes (columns). Yellow outlines mark the predicted SAM mask, cyan outlines mark ground truth, and red dots mark the selected click positions; per-image IoU is printed below each panel. The RL fine-tune is the only method that recovers a complete mask on every query, while Top-K argmax fails outright on park bench, similarity-weighted FPS fragments under domain difficulty, and BC v2 collapses on park bench and coconut at the longer click horizon.],
  placement: top,
  scope: "parent",
) <fig:representative_examples>

= Introduction

Single-shot semantic segmentation asks a model to delineate every instance of an object class in a query image, given only a single annotated example of that class. The setting is attractive because it sidesteps the expensive per-class supervision that conventional segmentation networks require, and it aligns with how practitioners often operate in the wild, where a handful of reference annotations must generalize to unseen scenes. Recent progress in self-supervised representation learning @oquab2023dinov2 and promptable segmentation @kirillov2023sam has made this regime increasingly tractable. In particular, the combination of a frozen vision transformer for feature extraction and the Segment Anything Model (SAM) for mask decoding has emerged as a dominant template, because it decouples class-agnostic shape priors from semantic correspondence and requires no fine-tuning on the target domain.

Within this template, the standard pipeline proceeds in three stages. A self-supervised encoder, typically DINOv2, embeds both the example and the query image into dense feature grids. A class prototype is then formed by masked-average-pooling the example features over the annotated region, and a per-pixel cosine similarity map is computed between this prototype and the query features. Finally, $N$ point prompts are extracted from the similarity map and passed to SAM, which produces the final mask. The first two stages are largely settled, in the sense that prototype construction and similarity computation have well-understood closed-form definitions. The third stage, by contrast, is an open design choice. The similarity map is dense and continuous, while SAM consumes a small discrete set of click locations, and the reduction from one to the other is neither obvious nor canonical.

This reduction matters more than it is often credited for. The naive choice of selecting the $N$ pixels with the highest similarity scores tends to concentrate points on a single high-confidence interior region of the object, because the similarity surface is smooth and unimodal over that region. SAM then receives redundant prompts that provide little additional disambiguating information about object extent, boundaries, or the presence of multiple instances. The working hypothesis across much of the recent literature is that _spatial spread_, jointly with similarity magnitude, is what governs mask quality, and a variety of heuristics, including non-maximum suppression, Farthest Point Sampling (FPS), and clustering-based selectors, have been proposed in service of that intuition. Yet these strategies are typically introduced as components of larger systems and compared only incidentally, leaving the relative merits of the underlying selection rules poorly characterized.

We address this gap with a head-to-head benchmark of eleven non-trained point selection strategies, two behavioral-cloning policies of varying expressiveness, and a reinforcement-learning fine-tune, all evaluated on FSS-1000 @li2020fss1000 over $N in {1, 2, 3, 5, 7, 10}$. All methods share an identical front-end and back-end, namely a DINOv2 ViT-L/14 encoder and a SAM ViT-H decoder, so that the sole source of variation is how $N$ prompt locations are drawn from the shared similarity map. To remove a residual source of confound, we additionally quantize every selector's output to a shared $37 times 37$ grid before passing it to SAM, so that heuristic, imitation, and reinforcement-learning policies all operate in a single action space. Hyperparameters are tuned on a held-out validation split under a frozen-test protocol, ensuring that reported numbers reflect genuine generalization rather than test-set selection.

The empirical findings stack to a concrete narrative. The trivial Top-K argmax baseline achieves $0.585$ mean IoU at $N = 1$ and decays monotonically to $0.379$ at $N = 10$, confirming that similarity-redundant points actively degrade SAM's output. The strongest heuristic, similarity-weighted FPS at $alpha = 0.75$, attains $0.768$ at $N = 5$. A greedy oracle reaches $0.956$ at the same budget, indicating substantial headroom above any heuristic. Behavioral cloning of the oracle reaches $0.672$ at $N = 5$, narrowly underperforming the strongest heuristic and exhibiting the same plateau-and-decline shape. Reinforcement-learning fine-tunes of the cloned policy reach $0.864$ at $N = 5$ and $0.866$ at $N = 10$, with absolute gaps of $0.096$ and $0.136$ over the strongest heuristic and $0.193$ and $0.281$ over the cloned policy. The RL policies' per-step trajectories rise sharply through six clicks and then sit on a high plateau, in contrast to the plateau-and-decline shape of every other selector studied here. The contribution of this work is therefore both a controlled benchmark of how heuristic and imitation selectors scale with $N$ under a single comparable action space, and a positive empirical demonstration that reward-driven fine-tuning is the operationally correct response to the ceiling identified by the benchmark.

#figure(
  image("figures/02_state_action.pdf", width: 90%),
  caption: [Policy state and action representation. The state $s_t$ is a nine-channel tensor at $37 times 37$ resolution (DINO similarity map, projected query features, click-history mask, current SAM mask, three step-counter planes, two coordinate planes), and the policy emits a logit over the same $37 times 37$ grid with previously-clicked cells masked out before sampling.],
  placement: top,
  scope: "parent",
) <fig:state_action>

= Related Work

== Few-shot semantic segmentation

Few-shot semantic segmentation has been driven by a sequence of architectures that aggregate dense correspondences between a support image-mask pair and a query image. Early approaches such as PFENet @tian2020pfenet and HSNet @min2021hsnet rely on fixed CNN encoders and learned aggregation modules. BAM @lang2022bam reframes the problem by explicitly distinguishing base and meta classes. VAT @hong2022vat introduces a 4D Swin transformer for cost aggregation, and DCAMA @shi2022dcama and HDMNet @peng2023hdmnet refine dense cross-attention strategies. These methods reach strong mean IoU on FSS-1000 by exploiting rich correspondence structure between support and query, but they require training on the few-shot task itself and assume the query mask can be regressed densely. Our work targets a different operating point: rather than producing the mask from the correspondence directly, we use the correspondence only to decide where to place a small number of click prompts, and let a frozen general-purpose mask decoder do the segmentation.

== Promptable segmentation foundation models

The emergence of SAM @kirillov2023sam and its sequel SAM2 @ravi2024sam2 has made one-shot mask production tractable from a small number of point or box prompts, with no per-class fine-tuning. SegGPT @wang2023seggpt takes a different route, training a single model that conditions on an arbitrary in-context example. Matcher @liu2024matcher and PerSAM @zhang2023persam pair SAM with feature-matching strategies to enable training-free few-shot segmentation, and SANSA @torres2025sansa adapts SAM2 with a small trained adapter for the one-shot setting. These methods all consume some form of prompt or example, but vary widely in how much information they pass to the segmentation backbone. Our work isolates the simplest version of this operating point, namely a small set of positive click prompts, and asks how the choice of prompts affects mask quality on a fixed backbone.

== Click-prompt training and interactive segmentation

A separate line of work trains networks to produce or simulate clicks for interactive segmentation. RITM @sofiiuk2022ritm and SimpleClick @liu2023simpleclick train iteratively with simulated user clicks using error-region heuristics, and FocalClick @chen2022focalclick refines the click-budget regime. These methods operate in a fundamentally different setting from ours because the user (or simulator) provides the click sequence; the network is trained to consume clicks rather than to produce them. To our knowledge, the present work is the first systematic comparison of heuristic, imitation, and reward-driven point selection on a unified action space against a frozen SAM decoder, with the explicit goal of understanding how the prompt-selection rule alone affects downstream mask quality.

#figure(
  image("figures/03_policy_arch.pdf", width: 80%),
  caption: [Policy network architecture. Three convolutional blocks form a shared backbone over the nine-channel input. The actor head is a $1 times 1$ convolution producing $37 times 37$ logits, masked by previously-clicked cells before sampling. The value head is a global-average pool followed by an MLP scalar baseline used by PPO's advantage estimator.],
  placement: top,
  scope: "parent",
) <fig:policy_arch>

= Method

== Pipeline and notation

We benchmark thirteen point selection strategies under a shared single-shot semantic segmentation pipeline. Each episode consists of a support image with a binary support mask and a query image whose ground-truth mask is held out for evaluation. A frozen DINOv2 ViT-L/14 encoder maps both images to dense patch features at $224 times 224$ resolution, and patch features are bilinearly upsampled to the input grid so that every pixel carries a feature vector. The support prototype $p in RR^d$ is obtained by masked average pooling of the support feature map under the support mask, and the query similarity map is the cosine similarity between $p$ and each query feature. We denote this map by $S in [0, 1]^(H times W)$, where $H = W = 224$. The map is precomputed once per episode and cached, so every selection strategy receives the same input and any differences in downstream segmentation are attributable solely to point selection.

Given a fixed budget $N$, a selection strategy is a deterministic or stochastic function that returns a point set $cal(P)_N = {(x_i, y_i)}_(i=1)^(N)$ with $(x_i, y_i) in {1, dots, W} times {1, dots, H}$. The point set is passed to a frozen SAM ViT-H decoder, with every click treated as a positive label and no negative or box prompts supplied, and the decoder returns a single binary mask that is compared against the query ground truth. To make heuristic, imitation, and reinforcement-learning selectors directly comparable at the prompt level, every chosen pixel coordinate is then quantized to the nearest center of a shared $37 times 37$ grid before being handed to SAM. The grid resolution arises naturally from the BC oracle's candidate set, defined on this grid for tractable training, and we apply the same quantization to every selection rule so that all methods operate in a single action space. The quantization step does not modify any selection rule, only the spatial precision of the prompts SAM receives.

#figure(
  image("figures/01_rl_loop.pdf", width: 80%),
  caption: [Reinforcement-learning interaction loop. At each step the policy maps the multi-channel state to a $37 times 37$ logit, samples a discrete click cell, hands it to SAM, and receives a reward equal to the change in IoU between the new and previous mask; the episode terminates after $N$ clicks.],
  placement: top,
  scope: "parent",
) <fig:rl_loop>

== Heuristic selectors

We evaluate eleven non-trained selection rules. _Top-K argmax_ picks the $N$ pixels with the highest values of $S$. _Top-K with non-maximum suppression (Top-K NMS)_ iteratively appends the current $arg max$ of $S$ to $cal(P)_N$ and then sets $S(x', y') = -infinity$ for every pixel within Euclidean radius $r$ of the chosen point; we use $r = 14$. _Farthest Point Sampling (FPS)_ seeds with the global $arg max$ of $S$ and iteratively appends the pixel that maximizes the minimum Euclidean distance to all previously chosen points. _Similarity-weighted FPS_ scores each candidate as $alpha dot S(x, y) + (1 - alpha) dot tilde(d)(x, y)$ with $alpha = 0.75$, where $tilde(d)$ is the normalized minimum distance to $cal(P)$. _Top-K to k-means_ takes the $K' = 256$ highest-similarity pixels, clusters them into $N$ groups via $k$-means, and returns the highest-similarity pixel per cluster. _Local-maxima peaks_ detects local maxima of $S$ subject to a minimum-separation constraint of six pixels and returns the top $N$. _Connected-component centers_ thresholds $S$ at $tau = 0.75$, extracts $8$-connected components, and selects the $arg max$ of $S$ within each component. _Mean-shift modes_ runs mean-shift on similarity-weighted pixel coordinates with bandwidth six and returns the top $N$ modes. _Quantile-spaced_ sorts pixels by similarity in descending order and picks at evenly spaced quantiles. _Similarity-weighted random_ samples $N$ points without replacement from the categorical distribution with probabilities $p(x, y) prop exp(S(x, y) \/ T)$ at $T = 0.05$. _Determinantal Point Process (DPP)_ samples $cal(P)_N$ from a $k$-DPP with quality scores $q_i = S(x_i, y_i)$ and a Gaussian diversity kernel of length-scale $ell = 18$.

== Behavioral-cloning policy

In addition to the eleven heuristics, we evaluate a learned policy trained by behavioral cloning (BC) on a greedy oracle. The greedy oracle is defined operationally. For each training episode, we discretize the $224 times 224$ query grid to a $37 times 37$ candidate grid and, for each candidate position $(x_c, y_c)$, query SAM under the prompt set $cal(P)_t union {(x_c, y_c)}$ and record the resulting IoU against the ground-truth mask. The oracle's $t$-th click is the candidate that maximizes this IoU. Because the oracle's first $k$ clicks are identical for any $N >= k$ by construction, a single $N = 10$ trajectory yields oracle labels for every smaller budget, and we cache trajectories per episode to disk so that the imitator never re-invokes SAM during training. On the FSS-1000 validation split this oracle reaches mean IoU $0.948$ at $N = 2$, $0.952$ at $N = 3$, $0.956$ at $N = 5$, and $0.955$ at $N = 10$, confirming that the $37 times 37$ grid resolution is not the bottleneck and that substantial headroom exists above the heuristics.

The BC policy network ingests the multi-channel state shown in @fig:state_action and emits a logit map at the $37 times 37$ grid resolution. The state $s_t$ is a nine-channel tensor at $37 times 37$ resolution: the DINO similarity map and projected query features as query evidence, the click-history mask and current SAM mask as click and mask state, three planes encoding the step index, target budget, and click count, and two coordinate planes acting as a spatial prior. The policy emits a logit map at the same resolution, with cells already used by previous clicks masked out before sampling. The loss is a Gaussian-kernel-density formulation of cross-entropy in which the oracle target is rendered as a Gaussian heatmap with $sigma = 2$ grid cells, so that the gradient signal degrades gracefully near the correct cell rather than treating any non-exact prediction as equally wrong. We add an auxiliary IoU loss term that, on a sub-batch of training examples, decodes the policy's argmax click and computes IoU against the ground-truth mask, providing a small, IoU-aligned supervisory signal. To match the inference-time setting, where re-clicking an already-clicked cell is meaningless, we mask previously-clicked cells out of the policy's logit space at training time. We train one policy per budget $N in {2, 5, 10}$ on the FSS-1000 train classes, select checkpoints by full-validation rollout IoU on the $450$ validation episodes, and evaluate on the held-out test split using the same eval harness as the heuristic baselines. To isolate the contribution of the architectural choices, we additionally train an ablation, denoted _BC v1_, that restricts the policy input to $S$ and the click-history mask alone, with no DINO query features, no Gaussian-kernel labels, no train-time masking, and no auxiliary IoU loss. The contrast between BC v1 and the full BC policy quantifies how much of the BC headroom these design choices recover.

== Reinforcement-learning fine-tune

The behavioral-cloning policy provides a strong initialization, but its training signal is the oracle's click identity rather than SAM's mask quality. To align the optimization signal with the actual evaluation criterion, we additionally fine-tune the cloned policy with reinforcement learning using SAM's IoU as the per-step reward. The setting is naturally formulated as a finite-horizon Markov decision process, illustrated in @fig:rl_loop. The state at step $t$ is $s_t = (Q, S, C_t, M_(t-1))$, where $Q$ denotes the projected DINOv2 query features, $S$ is the cosine similarity map, $C_t$ is the binary click-history mask after $t-1$ placements, and $M_(t-1)$ is SAM's mask under the prior prompt set. The action $a_t$ is a discrete pixel on the same $37 times 37$ grid the BC oracle was defined on, which preserves warm-start consistency. The reward at step $t$ is the marginal IoU gain $r_t = "IoU"(M_t, M^*) - "IoU"(M_(t-1), M^*)$, where $M^*$ is the ground-truth mask.

We use proximal policy optimization (PPO) @schulman2017ppo with the categorical policy expressed as a softmax over the $37 times 37$ logit map produced by the BC network. A linear value head is appended to the same backbone, yielding the shared-backbone actor-critic architecture in @fig:policy_arch. Three convolutional blocks form a shared backbone over the nine-channel input. The actor head is a $1 times 1$ convolution producing $37 times 37$ logits, masked by previously-clicked cells before sampling. The value head is a global-average-pool plus MLP scalar baseline used by PPO's advantage estimator. The policy is initialized from the BC v2 best checkpoint, and a Kullback-Leibler regularization term $beta dot "KL"(pi_theta || pi_("BC"))$ is added to the loss to anchor the fine-tune to the imitation prior; we initialize $beta = 0.1$ and decay it linearly to $0.01$ over the first quarter of training. The full warm-start-then-fine-tune pipeline is shown in @fig:training_pipeline. PPO collects rollouts from $32$ vectorized environments, computes generalized advantages @schulman2016gae, and updates the policy with a clipped surrogate objective regularized by the KL anchor to the frozen BC reference.

#figure(
  image("figures/04_training_pipeline.pdf", width: 90%),
  caption: [BC warm-start to PPO fine-tuning. The actor weights are copied from the BC checkpoint and the value head is initialized fresh. PPO collects rollouts from $32$ vectorized environments, computes generalized advantages, and updates the policy with a clipped surrogate objective regularized by a KL anchor to the frozen BC reference.],
  placement: top,
  scope: "parent",
) <fig:training_pipeline>

We use standard PPO hyperparameters: clip $epsilon = 0.2$, GAE $lambda = 0.95$, $gamma = 1.0$, four update epochs per rollout, and an effective rollout batch of $32$ vectorized environments times episode length. Across one million environment steps, the KL anchor coefficient $beta$ decays linearly from $0.1$ to $0.01$, the entropy coefficient from $0.01$ to $0.001$, and the learning rate from $3 times 10^(-4)$ to zero. Early steps keep $pi_theta$ close to the BC reference; late steps relax the constraints and let the agent optimize the change in IoU directly. SAM image embeddings are precomputed and cached on disk for the train, validation, and test splits at both ViT-B and ViT-H resolutions, so that the inner training loop calls only SAM's mask decoder. SAM ViT-B is used during PPO training to reduce per-call cost; final test evaluation uses the same SAM ViT-H decoder used by every other method, keeping the comparison protocol-clean. The mask-decoder forward path is run in float32 during training to preserve numerical parity with the standard predictor, since we observed that bf16 reduced precision changed predicted masks enough to bias the reward.

We report two RL fine-tune runs, both warm-started from the BC v2 policy at the matching budget and trained for one million environment steps. The $N = 5$ run targets the budget at which heuristic methods peak; the $N = 10$ run targets the longer horizon at which heuristic and imitation policies exhibit their characteristic late-decline failure mode.

== Evaluation protocol

We evaluate on FSS-1000 under a class-disjoint split in which the validation and test class pools are entirely disjoint, and we sample $450$ episodes per split. Each episode is a tuple consisting of a support image, its binary support mask, a query image, and a query ground-truth mask, with support and query drawn from the same class. Selection strategies are evaluated at point budgets $N in {1, 2, 3, 5, 7, 10}$. Each heuristic with a tunable hyperparameter has it grid-searched on the validation split, frozen, and then run once on the test split. For stochastic methods we average over five seeds; deterministic methods run once with $"seed" = 0$.

To position our pipeline against external few-shot segmentation methods, we additionally evaluate on a $66$-class subset of the canonical FSS-1000 one-shot benchmark @li2020fss1000 disjoint from our training set, yielding $660$ test episodes under the canonical $10$-queries-per-class protocol. External methods are re-evaluated on the same $660$-episode subset using their respective public eval scripts, with their mIoU and foreground-background IoU computed on identical inputs to ours. As a sanity check, we re-ran Matcher on the full canonical $240$-class test set and reproduced its originally reported mean IoU of $0.872$ to within numerical noise.

We report intersection-over-union (IoU) as the primary metric, accompanied by the Dice coefficient and boundary-IoU and per-call wallclock time on a single GPU.

= Experiments

== FSS-1000 in-domain benchmark

#figure(
  image("figures/miou_vs_n.pdf", width: 100%),
  caption: [Mean IoU on the FSS-1000 test set as a function of point budget $N$, under the unified $37 times 37$ action space. The RL fine-tune (Garnet triangles) sits well above every other method at both trained budgets. The four Tier-1 heuristics cluster within $0.05$ IoU of one another and peak at $N in {3, 5}$. Top-K argmax decays monotonically; pure FPS and quantile-spaced collapse past $N = 1$.],
  placement: top,
) <fig:miou_vs_n>

#figure(
  caption: [Headline comparison on FSS-1000 test ($450$ episodes per cell), showing trained methods alongside the strongest heuristic anchor and a trivial-baseline reference. Greedy oracle is a non-comparable upper bound (validation only).],
  placement: top,
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [$N=1$], [$N=2$], [$N=3$], [$N=5$], [$N=7$], [$N=10$],
    ),
    table.hline(),
    [Greedy oracle (val, upper bound)], [0.920], [0.948], [0.952], [0.956], [0.956], [0.955],
    table.hline(stroke: 0.4pt),
    [*RL fine-tune (PPO)*], [--], [--], [--], [*0.864*], [--], [*0.866*],
    table.hline(stroke: 0.4pt),
    [BC v2 (DINO + masked + Gauss + IoU aux)], [--], [0.634], [--], [0.672], [--], [0.586],
    [BC v1 (sim-map only)], [--], [0.638], [--], [0.530], [--], [0.462],
    table.hline(stroke: 0.4pt),
    [Sim-weighted FPS ($alpha=0.75$, best heuristic)], [0.585], [0.699], [0.741], [0.768], [0.756], [0.731],
    [Top-K argmax (trivial baseline)], [0.585], [0.579], [0.571], [0.502], [0.445], [0.379],
    table.hline(),
  )
) <tab:test_results>

@tab:test_results and @fig:miou_vs_n report test-set mean IoU for all heuristics, both BC variants, and the RL fine-tune, evaluated at $N in {1, 2, 3, 5, 7, 10}$ on $450$ episodes per cell under the unified action space. @tab:heuristic_sweep in the appendix lists every heuristic at every budget for completeness. The picture separates into clean tiers. The strongest heuristic, similarity-weighted FPS at $alpha = 0.75$, reaches $0.768$ at $N = 5$ and stays above $0.73$ across $N in {3, 5, 7, 10}$. Top-K NMS, Top-K to k-means, and local-maxima peaks track within $0.05$ IoU of similarity-weighted FPS at every budget. A second tier composed of DPP, connected-component centers, and similarity-weighted random sits in the $0.65$ to $0.69$ range. Mean-shift modes and Top-K argmax form a weaker third tier, with Top-K argmax notably the only method whose IoU degrades monotonically and steeply with $N$, dropping $20.6$ IoU points from $N = 1$ to $N = 10$ as redundant nearby clicks confuse SAM's prompt encoder. Pure FPS and quantile-spaced are catastrophic failures, falling below $0.20$ IoU past $N = 1$ because they place clicks in low-similarity regions that lie off-object. Nine of the eleven heuristics report identical IoU at $N = 1$ ($0.585$), validating the implementation: with a single output point, all of these rules reduce to the argmax of the cosine-similarity map snapped to the nearest grid cell.

== Imitation policies

The full BC v2 policy reaches $0.634$ at $N = 2$, $0.672$ at $N = 5$, and $0.586$ at $N = 10$, narrowly underperforming the strongest heuristic at $N = 5$ by $0.096$ IoU. The BC v1 sim-map-only ablation reaches $0.638$, $0.530$, and $0.462$ at the same budgets. The two policies coincide at $N = 2$ to within $0.004$ IoU but diverge at multi-click budgets, indicating that the architectural choices distinguishing v2 from v1 (DINOv2 query features, train-time masking of previously-clicked cells, Gaussian-kernel soft labels, and the auxiliary IoU loss) collectively recover $14.2$ IoU points at $N = 5$ and $12.4$ at $N = 10$ but do nothing for the easy single-click case. The cluster-spread metric on BC v2's test rollouts confirms that train-time masking behaves as intended at small budgets but loses force at large ones: the mean pairwise click distance is $47.9$ pixels at $N = 2$ but contracts to $34.1$ pixels at $N = 10$, indicating that the policy still drifts back into spatially correlated regions across multiple steps even when immediate re-clicking is forbidden.

== Per-step trajectory analysis

#figure(
  image("figures/per_step_n5.pdf", width: 100%),
  caption: [Per-step rollout IoU at $N = 5$ on FSS-1000 test ($450$ episodes), comparing BC v2 (Atlantic squares) against the PPO RL fine-tune warm-started from BC v2 (Garnet triangles). The RL trajectory rises monotonically across all five clicks and clears the strongest non-trained baseline (dashed reference at $0.768$) by step $2$, while BC v2 stays below the baseline at every step.],
) <fig:per_step_n5>

#figure(
  image("figures/per_step_n10.pdf", width: 100%),
  caption: [Per-step rollout IoU at $N = 10$ on FSS-1000 test, comparing BC v2 against the RL fine-tune at $N = 10$. BC v2 peaks at click $3$ ($0.645$) and declines monotonically through step $10$ ($0.586$); RL rises sharply through step $6$ and then sits on a flat plateau between $0.866$ and $0.869$ through step $10$, sustaining its peak quality across the entire long-horizon budget.],
) <fig:per_step_n10>

@fig:per_step_n5 plots the per-step rollout IoU of BC v2 and the PPO fine-tune at $N = 5$. The two curves diverge immediately. By step $2$, RL reaches $0.786$ while BC reaches $0.599$, and the RL trajectory is already above the strongest non-trained baseline shown as the dashed reference line. By step $3$, RL is at $0.846$ while BC is at $0.636$. The RL curve continues to rise through clicks $4$ and $5$ to its final value of $0.864$, while the BC curve climbs only to $0.672$. The gap between the two trajectories at every step is at least $0.187$ IoU.

The longer-horizon picture in @fig:per_step_n10 is sharper still. The RL fine-tune at $N = 10$ rises from $0.554$ at step $1$ to $0.777$ at step $2$, $0.831$ at step $3$, $0.852$ at step $4$, $0.863$ at step $5$, and reaches $0.868$ at step $6$. From step $6$ onward, the trajectory sits on a flat plateau between $0.866$ and $0.869$, with no sign of late decline. The BC v2 curve on the same axes peaks at step $3$ ($0.645$) and degrades through every subsequent step to $0.586$ at step $10$. The plateau-and-decline shape is shared by every heuristic and by BC v2, suggesting that imitation alone cannot break a SAM-imposed ceiling. The RL trajectories' rise-then-plateau shape, sustained across both the short-horizon and long-horizon budgets, indicates that reward-driven training reshapes the per-step curve.

== Reinforcement-learning fine-tune

The two PPO fine-tunes reach mean IoU $0.864$ at $N = 5$ and $0.866$ at $N = 10$ on test, with absolute improvements of $0.096$ and $0.136$ over the strongest non-trained heuristic at the respective budgets and $0.193$ and $0.281$ over the BC v2 policy from which each fine-tune was warm-started. Both runs clear the heuristic floor of approximately $0.77$ and recover roughly one third of the residual headroom to the greedy-oracle upper bound at $N = 5$ and roughly one half of it at $N = 10$. The best PPO checkpoint at $N = 5$ occurs at update $5{,}250$ of $6{,}250$ with validation rollout IoU $0.903$; the best checkpoint at $N = 10$ occurs at update $3{,}000$ of $3{,}125$ with validation rollout IoU $0.895$. The mean pairwise click distance on test rollouts is $69.5$ pixels at $N = 5$ and $69.3$ pixels at $N = 10$, essentially identical across the two budgets, indicating that reward-driven training maintains the same wide click distribution as the budget grows rather than contracting toward a tight cluster as BC v2 does ($34.1$ pixels at $N = 10$).

== Comparison to external few-shot segmentation methods

#figure(
  caption: [Comparison against external few-shot methods on the canonical FSS-1000 one-shot $66$-class disjoint subset ($660$ episodes).],
  table(
    columns: (auto, auto),
    align: (left, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [mean IoU],
    ),
    table.hline(),
    [SANSA (SAM2-Hiera-L + adapter) @torres2025sansa], [0.923],
    [Matcher (DINOv2-L + SAM-H, training-free) @liu2024matcher], [0.892],
    [SegGPT @wang2023seggpt], [0.867],
    [PerSAM @zhang2023persam], [0.741],
    table.hline(stroke: 0.4pt),
    [RL fine-tune (PPO, $N=5$)], [0.876],
    [RL fine-tune (PPO, $N=10$)], [0.875],
    table.hline(stroke: 0.4pt),
    [Sim-weighted FPS ($alpha=0.75$, $N=5$)], [0.762],
    [BC v2 (DINO + masked + Gauss + IoU aux, $N=5$)], [0.641],
    [Top-K argmax ($N=5$)], [0.474],
    table.hline(),
  )
) <tab:sota_comparison>

@tab:sota_comparison reports our pipeline against four external one-shot segmentation methods on the $66$-class canonical-disjoint subset. The PPO fine-tune at $N = 5$ reaches $0.876$ mean IoU on the canonical-disjoint subset, slightly higher than its performance on our v1 split ($0.864$). The PPO fine-tune at $N = 10$ reaches $0.875$. Among the external methods, SANSA leads at $0.923$ and Matcher follows at $0.892$. Our RL fine-tune surpasses SegGPT ($0.867$) and PerSAM ($0.741$) but trails the two strongest external methods. The most informative single comparison is against Matcher, since the two methods share an identical DINOv2-L plus SAM-H backbone and differ only in how the SAM decoder is prompted: Matcher uses a training-free dense-correspondence prompting strategy that goes beyond the strict positive-click vocabulary, while our RL policy emits at most ten positive clicks. The $0.016$ mIoU gap between the two indicates that, on the same backbone and the same canonical test, a learned point selector with a strict $N <= 10$ point-prompt budget closely approaches the quality of a more expressive prompting strategy. The $0.047$ mIoU gap to SANSA is best read as the cost of restricting the action space to grid-quantized positive clicks rather than as a deficiency of the RL training procedure itself, since SANSA replaces the entire encoder backbone with SAM2 and adds a trained adapter network.

The relative ordering among our methods is preserved on the canonical-disjoint subset. RL clears every heuristic by a wide margin. BC v2 underperforms its own v1 numbers at the longer budgets ($-0.031$ at $N = 5$, $-0.030$ at $N = 10$) while RL slightly outperforms its v1 numbers ($+0.012$ at $N = 5$, $+0.009$ at $N = 10$), suggesting that reward-driven policies are more robust to class-distribution shift than imitation policies trained from oracle clicks.

== Ablations

We report three ablations using existing data, each isolating one design choice.

_Effect of input features (BC v1 vs BC v2)._ The BC v1 ablation restricts the policy input to the similarity map and click-history mask alone, with no DINO query features, no Gaussian-kernel soft labels, no train-time masking of previously-clicked cells, and no auxiliary IoU loss. Under this stripped configuration, the BC policy reaches only $0.530$ at $N = 5$ and $0.462$ at $N = 10$. Adding back the four architectural components (the DINO query feature stream, masked self-supervision, Gaussian soft labels, and auxiliary IoU loss) collectively recovers $14.2$ IoU points at $N = 5$ and $12.4$ at $N = 10$, while leaving the trivial $N = 2$ case essentially unchanged. The ablation therefore quantifies that the headroom recoverable by imitation supervision depends critically on what the policy is allowed to see and how its loss is shaped, but that imitation alone, even with all four enhancements, still narrowly underperforms the strongest heuristic at $N = 5$.

_Effect of warm-start initialization._ The PPO fine-tune is warm-started from the BC v2 best checkpoint and KL-anchored to that same reference policy. Without the warm start, the policy network and the value head would both be initialized from scratch, and the KL anchor would reduce to a regularizer toward a degenerate prior. The relevant comparison in our data is between the BC v2 starting point ($0.672$ at $N = 5$) and the PPO converged checkpoint ($0.864$ at $N = 5$), demonstrating that PPO recovers an additional $0.193$ IoU starting from a non-degenerate prior. The KL anchor at $beta = 0.1$ decaying to $0.01$ keeps the policy close to the BC reference early in training, when the value-function estimate is still noisy and unconstrained gradient steps would be most likely to destroy the warm-start signal.

_Effect of action-space discretization._ The unified $37 times 37$ grid discretization is itself a methodological choice that could be questioned as an artificial constraint. We compare the heuristic numbers under the grid-snapped protocol against the same heuristics evaluated at full $224 times 224$ pixel resolution on our v1 split. The strongest heuristic, similarity-weighted FPS at $alpha = 0.75$, scores $0.759$ at $N = 5$ at full resolution and $0.768$ at $N = 5$ under grid quantization, a shift of $+0.009$ IoU. The grid-snapping step actually slightly improves the heuristics on average because it enforces a minimum spacing between selected pixels, partially solving the redundant-clicks problem on its own. The Top-K argmax decay shape is preserved: $0.594 -> 0.586 -> 0.499$ at full resolution becomes $0.585 -> 0.579 -> 0.502$ under grid quantization. The RL win is therefore not an artifact of the discretization; the grid step alone fails to close the gap to $0.864$ that the RL policy reaches under the same protocol.

== Cross-domain smoke test

We additionally ran a small cross-domain smoke test on Kvasir-SEG, a polyp segmentation dataset from medical imaging. Ten random support-query image pairs were sampled, with no class-disjoint structure (the dataset has only the polyp class). The same DINOv2-L sim-map and SAM ViT-H decoder were used; the heuristic, BC v2, and RL policies were applied without retraining. The strongest heuristic, similarity-weighted FPS at $N = 5$, reached only $0.149$ mean IoU on the ten pairs. The BC v2 policy reached $0.357$ and the RL fine-tune reached $0.339$. All three values represent substantial degradation relative to FSS-1000, consistent with significant out-of-distribution shift from natural-image few-shot data to medical imagery. The heuristic crashes hardest because it relies entirely on the DINOv2 cosine similarity map, which itself degrades under domain shift; the learned policies (BC and RL), which take richer DINOv2 query features as additional input, degrade more gracefully but show no clear RL-over-BC advantage in this OOD setting. We treat this as a smoke test rather than a study, and discuss its implications further in @sec:limitations.

== Representative examples

@fig:representative_examples on the first page shows test-set overlays at $N = 10$ for three FSS-1000 query images and four method classes: Top-K argmax, similarity-weighted FPS, BC v2, and the PPO RL fine-tune. Each overlay marks the selected click positions in red, the predicted SAM mask in yellow, and the ground-truth mask in cyan, with the per-image IoU printed below each panel. The three queries span a representative range of difficulty. The _park bench_ scene is hard for confidence-only and imitation methods alike: Top-K argmax produces no mask at all (IoU $0.00$), similarity-weighted FPS produces a fragmented over-segmentation (IoU $0.16$), and BC v2 collapses at $N = 10$ to a partial mask (IoU $0.21$). The RL fine-tune is the only method that recovers a complete, well-aligned mask of the bench (IoU $0.92$). The _coconut_ scene is easier on average but still distinguishes the trained policies: BC v2 contracts to a tight cluster of clicks at $N = 10$ and the IoU collapses to $0.41$, while RL maintains a wide click distribution and reaches $0.96$. The _skateboard_ scene is a uniform-success case where every method scores within $0.03$ IoU of the others. The visual contrast confirms the quantitative story of @tab:test_results: the RL fine-tune is consistently competitive, BC has individual-episode failure modes at long horizons, and heuristics depend heavily on the scene.

== Inference cost

Wall-clock cost is not the limiting factor for any of the strategies considered. Most heuristic methods run in under thirty milliseconds per call on a single GPU at the resolutions used here. The slowest heuristic case is the DPP with $ell = 18$ at $N = 10$, which reaches roughly forty-five milliseconds because of the eigendecomposition of its kernel. The fastest are Top-K argmax and quantile-spaced selection at approximately seven milliseconds. The BC v2 and RL policies' per-step inference cost is dominated by the SAM decoder call itself; the policy network's contribution is a small additional CNN forward pass that runs in single-digit milliseconds.

= Discussion

== Imitation hits a ceiling, reward breaks it

The clearest empirical finding of this work is the contrast between the per-step trajectory shapes of imitation and reward-driven policies. The behavior of Top-K argmax is the cleanest diagnostic: its mean IoU falls monotonically from $0.585$ at $N = 1$ to $0.379$ at $N = 10$, a drop of $20.6$ points across the budget range. The mechanism is geometric. Confidence-only selection draws its top points from a tight neighborhood around the global similarity maximum, and adding more such points does not enrich the prompt set so much as reinforce a single locus. SAM's prompt encoder is designed to consume each click as an additional disambiguating constraint on the latent mask, but redundant clicks at essentially the same spatial location carry no new disambiguation. The four Tier-1 heuristics, which enforce spatial separation in different ways, all converge to within $0.05$ IoU at their respective peaks, suggesting that what SAM wants from its prompt set is decorrelation rather than any specific separation rule.

The behavioral-cloning policy provides a more interesting case. The greedy oracle that BC v2 imitates is itself SAM-aware, in the sense that each oracle click is selected by maximizing IoU under SAM. Yet a policy trained to clone the oracle's click identities does not match the oracle's per-step trajectory. The cloned policy reproduces a pattern of plateau and decline rather than the oracle's continued ascent, peaking at click step $3$ at $N = 10$ and degrading thereafter. Imitation alone, even of a strong oracle, appears to inherit the heuristic-style ceiling rather than break through it.

The PPO fine-tune at $N = 5$ reaches $0.864$, $0.096$ above the strongest heuristic and $0.193$ above BC v2. More importantly, the per-step trajectory in @fig:per_step_n10 rises sharply through step $6$ and then sits dead flat between $0.866$ and $0.869$ across steps $7$ through $10$. The plateau-and-decline shape that bounds the heuristic family and the imitation policy is broken cleanly by reward-driven training. The operative difference is the alignment of the optimization signal. Imitation forces the policy to commit to the specific cells the oracle chose at each step, which is brittle on the test distribution; reward-driven training lets the policy choose any cell whose click happens to improve SAM's mask, and over many gradient steps that flexibility lets the policy discover click sequences whose joint information content exceeds anything any single oracle trajectory exhibits.

== Spatial spread, similarity floor, and action-space effects

The catastrophic failures of pure FPS and quantile-spaced selection sharpen this picture from the opposite direction. Both collapse below $0.20$ mean IoU past $N = 1$. After the first seed, pure FPS optimizes spatial distance with no regard for feature similarity, and on the small objects typical of FSS-1000 _far from chosen points_ usually means _outside the object_. SAM treats every click as a positive label, so it grows the mask outward to encompass the resulting background clicks. Quantile-spaced selection has the same defect by construction. The general lesson is that any selector must enforce a similarity floor: every chosen point must lie in a region whose feature similarity is consistent with the support prototype, regardless of whether the rule is heuristic or learned.

The cluster-spread metric tells a complementary story for the learned policies. The mean pairwise click distance under RL is $69.5$ pixels at $N = 5$ and $69.3$ pixels at $N = 10$, essentially invariant across budgets. Under BC v2, the same metric contracts from $47.9$ pixels at $N = 2$ to $34.1$ pixels at $N = 10$, indicating that the imitation policy gradually re-introduces redundancy as the budget grows even when train-time masking explicitly penalizes immediate re-clicking. Reward-driven training discovers a budget-aware placement strategy; imitation discovers a fixed pattern that fails to use the longer horizon productively. The action-space ablation confirms this is not a discretization artifact: the heuristic numbers shift by less than $0.01$ IoU when the same selectors are evaluated under the unified $37 times 37$ grid versus full pixel resolution.

== Limitations and future work <sec:limitations>

Several caveats temper these conclusions. The benchmark was conducted on FSS-1000 alone, and the cross-domain smoke test on Kvasir-SEG suggests that all three method classes degrade substantially under medical-domain shift, with the heuristic family degrading hardest because of similarity-map degradation. We leave full medical-domain evaluation, including potentially domain-adapted features and proper episode protocols, to future work. All clicks in this study were treated as positive labels; neither negative-click prompts nor bounding-box prompts were explored, although both are first-class citizens in SAM's prompt vocabulary. Extending the policy's action space to include negative clicks is a particularly natural next step because negative clicks are the standard way to correct over-segmentation, and the present action space cannot issue them. The class-disjoint split rules out within-class memorization but does not probe cross-domain generalization at scale; a multi-dataset evaluation including Pascal-$5^i$ and COCO-$20^i$ would strengthen the headline claim. Finally, we report a single PPO seed per budget; multi-seed stability and the dependence on warm-start quality remain to be characterized.

= Conclusion

We presented a controlled comparison of point selection strategies for single-shot semantic segmentation under a shared DINOv2 and SAM pipeline on FSS-1000, with all selectors operating in a unified $37 times 37$ action space so that heuristic, imitation, and reinforcement-learning methods are directly comparable at the prompt level, and we additionally benchmarked the best of these methods against four external few-shot segmentation systems on the canonical FSS-1000 one-shot test protocol restricted to a $66$-class subset disjoint from our training set. Among eleven non-trained heuristics, similarity-weighted Farthest Point Sampling at $alpha = 0.75$ reaches $0.768$ mean IoU at $N = 5$. A behavioral-cloning policy trained on a strong greedy oracle reaches $0.672$ at the same budget, narrowly underperforming the strongest heuristic and exhibiting the same plateau-and-decline per-step shape that the heuristics do. Two PPO fine-tunes of the cloned policy with SAM's IoU as the per-step reward, anchored to the imitation prior by a KL term, reach $0.864$ at $N = 5$ and $0.866$ at $N = 10$ on test, with absolute improvements of $0.096$ and $0.136$ over the strongest heuristic at the respective budgets and $0.193$ and $0.281$ over imitation. The reinforcement-learning policies rise sharply through their first six clicks and then sit on a high plateau, breaking the plateau-and-decline shape that every other method exhibits. On the canonical FSS-1000 one-shot subset disjoint from our training set, the same policies reach $0.876$ at $N = 5$ and $0.875$ at $N = 10$, surpassing PerSAM and SegGPT and approaching Matcher, which uses an identical DINOv2-L plus SAM-H backbone with a richer prompting strategy. The empirical claim of the paper is that imitation alone cannot break the SAM-imposed ceiling that bounds the heuristic family, but that aligning the optimization signal with SAM's actual mask quality, via reinforcement learning warm-started from a behavioral-cloning prior, can.

#bibliography("refs.yaml", style: "ieee")

#set heading(numbering: "A.")
#counter(heading).update(0)

= Full heuristic sweep <appendix:heuristic-sweep>

#figure(
  caption: [Full heuristic sweep on FSS-1000 test ($450$ episodes per cell), under the unified action space. Frozen-best hyperparameters per method.],
  placement: top,
  scope: "parent",
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto),
    align: (left, right, right, right, right, right, right),
    stroke: none,
    table.hline(),
    table.header(
      [Method], [$N=1$], [$N=2$], [$N=3$], [$N=5$], [$N=7$], [$N=10$],
    ),
    table.hline(),
    [Sim-weighted FPS ($alpha=0.75$)], [0.585], [0.699], [0.741], [0.768], [0.756], [0.731],
    [Top-K + NMS ($r=14$)], [0.585], [0.663], [0.717], [0.732], [0.732], [0.712],
    [Top-K to k-means ($K'=256$)], [0.585], [0.702], [0.730], [0.718], [0.677], [0.628],
    [Local-maxima peaks (sep $=6$)], [0.585], [0.679], [0.723], [0.732], [0.688], [0.631],
    table.hline(stroke: 0.4pt),
    [DPP ($ell=18$)], [0.577], [0.657], [0.690], [0.681], [0.674], [0.649],
    [Connected-component centers ($tau=0.75$)], [0.585], [0.632], [0.653], [0.619], [0.593], [0.547],
    [Sim-weighted random ($T=0.05$)], [0.451], [0.589], [0.642], [0.646], [0.674], [0.668],
    [Mean-shift modes (bw $=6$)], [0.602], [0.642], [0.620], [0.556], [0.512], [0.460],
    [Top-K argmax], [0.585], [0.579], [0.571], [0.502], [0.445], [0.379],
    table.hline(stroke: 0.4pt),
    [Quantile-spaced], [0.585], [0.137], [0.092], [0.077], [0.077], [0.077],
    [Farthest Point Sampling], [0.585], [0.169], [0.062], [0.050], [0.043], [0.048],
    table.hline(),
  )
) <tab:heuristic_sweep>
